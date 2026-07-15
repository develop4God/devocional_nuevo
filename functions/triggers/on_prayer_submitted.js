// functions/triggers/on_prayer_submitted.js
// Firestore trigger: fires on new prayer document creation.
//
// Step 1: PII masking (synchronous — blocks display until done). Masking
//         must SUCCEED before any text derived from the prayer is written
//         anywhere a client can read it. See SECURITY_ASSESSMENT F-05: a
//         previous version of this file continued to Step 2 on masking
//         failure using the still-unmasked text, so a masking error paired
//         with an approval could publish raw originalText as maskedText.
//         On failure this now routes straight to needs_review and touches
//         no text field at all.
// Step 2: Moderation. originalText is CLEARED from the document once both
//         steps have run (success or moderation-failure fallback), so no
//         status other than 'pending'/'needs_review' — which only the owner
//         can read, per firestore.rules — is ever holding originalText.

"use strict";

const crypto = require("crypto");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");
const {createPrayerWallServices} = require("../service_locator");

/**
 * SECURITY_ASSESSMENT F-10: the client submits `authorId` as an unsalted
 * SHA-256(uid), which anyone who learns a uid can recompute — a pseudonym,
 * not an anonymizer. When PRAYER_AUTHOR_HMAC_SECRET is configured, replace
 * it with a keyed HMAC that only the holder of the secret can invert/link,
 * computed from the rule-verified `ownerUid` field (never the client's
 * submitted authorId). If the secret isn't configured, the client-submitted
 * value is left as-is — this upgrade is opt-in and non-breaking.
 *
 * @param {string|undefined} ownerUid
 * @returns {string|null}
 */
function computeAuthorPseudonym(ownerUid) {
  const secret = process.env.PRAYER_AUTHOR_HMAC_SECRET;
  if (!secret || !ownerUid) return null;
  return crypto.createHmac("sha256", secret).update(ownerUid).digest("hex");
}

/**
 * Firestore trigger: on_prayer_submitted
 * Fires whenever a new document is created in `prayers/{prayerId}`.
 *
 * Services are constructed via the DI factory (createPrayerWallServices) so
 * they can be injected/mocked in tests without modifying this handler.
 *
 * F-11 follow-up (found by adversarial validation, 2026-07-15): a Cloud
 * Functions v2 trigger only receives a Secret Manager secret in
 * process.env if it's explicitly listed in `secrets`. This trigger reads
 * GEMINI_API_KEY and PRAYER_AUTHOR_HMAC_SECRET but declared neither, so even
 * with the export fix above, deploying this function would still leave the
 * pipeline silently inert if either value lives in Secret Manager (the
 * pattern this codebase's own docs recommend, e.g. `firebase
 * functions:secrets:set GEMINI_API_KEY`) rather than a bare `.env` file.
 * Declaring them here is the correct fix if Secret Manager is in use; if
 * GEMINI_API_KEY is actually supplied via `.env` instead, this declaration
 * will make `firebase deploy` fail loudly with "secret not found" —
 * which, unlike the previous silent no-op, immediately surfaces the
 * mismatch instead of hiding it. Confirm which mechanism is actually in use
 * for this project before/at the next deploy.
 */
const onPrayerSubmitted = onDocumentCreated(
    {
      document: "prayers/{prayerId}",
      secrets: ["GEMINI_API_KEY", "PRAYER_AUTHOR_HMAC_SECRET"],
    },
    async (event) => {
      const prayerId = event.params.prayerId;
      const prayer = event.data?.data();

      if (!prayer) {
        logger.warn(`[onPrayerSubmitted] No data for prayer ${prayerId}`);
        return;
      }

      const db = admin.firestore();
      const ref = db.collection("prayers").doc(prayerId);
      const geminiApiKey = process.env.GEMINI_API_KEY;

      if (!geminiApiKey) {
        logger.error("[onPrayerSubmitted] GEMINI_API_KEY environment variable not set");
        return;
      }

      // Resolve all services via DI factory — no direct instantiation here.
      const {piiService, moderationService} = createPrayerWallServices({
        apiKey: geminiApiKey,
        db,
        logger,
      });

      const originalText = prayer.originalText || "";
      const language = prayer.language || "en";
      const authorPseudonym = computeAuthorPseudonym(prayer.ownerUid);

      // Step 1: PII Masking (synchronous — must complete before prayer is ever shown).
      let piiResult;
      try {
        piiResult = await piiService.mask(originalText, language);
      } catch (err) {
        logger.error(
            `[onPrayerSubmitted] PII masking failed for ${prayerId}: ${err.message}`,
        );
        // Do NOT touch maskedText/originalText — leave the document exactly
        // as the client wrote it (still readable only by its owner) and
        // route to needs_review so a human can retry or resolve it.
        const updates = {status: "needs_review"};
        if (authorPseudonym) updates.authorId = authorPseudonym;
        await ref.update(updates);
        return;
      }

      const maskedText = piiResult.maskedText;

      logger.info(
          `[onPrayerSubmitted] PII masking complete for ${prayerId} ` +
        `(modified: ${piiResult.wasModified})`,
      );

      // Step 2: Moderation
      try {
        const snapshot = await ref.get();

        if (!snapshot.exists) {
          logger.warn(`[onPrayerSubmitted] Prayer ${prayerId} not found — skipped`);
          return;
        }

        const moderationResult = await moderationService.moderate(maskedText, language);

        // Determine status from moderation result.
        // F-03 follow-up: an "approved" verdict is only honored at >= 0.75
        // confidence — previously a low-confidence approval still published
        // immediately, when the same low confidence on a non-approval would
        // have routed to needs_review instead. A low-confidence approval is
        // exactly the shape a partially-successful injection would produce.
        const status = moderationResult.isPastoral ? "pastoral" :
                     (moderationResult.approved && moderationResult.confidence >= 0.75) ? "approved" :
                     moderationResult.confidence < 0.75 ? "needs_review" :
                     "rejected";

        // Single merged write with all fields from both PII masking and moderation
        const updates = {
          maskedText,
          originalText: admin.firestore.FieldValue.delete(), // remove from doc
          piiMasked: true,
          piiWasModified: piiResult.wasModified,
          status,
          moderationScore: moderationResult.confidence,
          moderationFlag: moderationResult.flag,
          moderationReason: moderationResult.reason,
          moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        if (authorPseudonym) updates.authorId = authorPseudonym;

        await ref.update(updates);

        logger.info(
            `[onPrayerSubmitted] Prayer ${prayerId} processed ` +
        `(piiModified: ${piiResult.wasModified}, status: ${status}, ` +
        `flag: ${moderationResult.flag}, confidence: ${moderationResult.confidence})`,
        );
      } catch (err) {
        // RATE_LIMIT or other transient error: PII masking already succeeded,
        // so maskedText is safe to publish, but moderation hasn't run — route
        // to needs_review rather than leaving status stuck at 'pending'
        // forever (there is currently no retry queue consuming 'pending'
        // prayers; see SECURITY_ASSESSMENT for the moderation_queue_handler
        // wiring gap).
        logger.warn(
            `[onPrayerSubmitted] Moderation failed for ${prayerId}: ${err.message}`,
        );

        const updates = {
          maskedText,
          originalText: admin.firestore.FieldValue.delete(),
          piiMasked: true,
          piiWasModified: piiResult.wasModified,
          status: "needs_review",
        };
        if (authorPseudonym) updates.authorId = authorPseudonym;

        await ref.update(updates);
      }
    },
);

module.exports = {onPrayerSubmitted, computeAuthorPseudonym};
