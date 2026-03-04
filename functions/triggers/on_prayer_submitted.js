// functions/triggers/on_prayer_submitted.js
// Firestore trigger: fires on new prayer document creation.
//
// Step 1: PII masking (synchronous — blocks display until done)
//         originalText is CLEARED from the document after masking so that
//         approved prayers never expose raw user text to clients.
// Step 2: Run moderation via injected ModerationQueueHandler
//
// Cloud Tasks configuration (set in Firebase console or Terraform):
//   maxDispatchesPerSecond: 0.2  (= 12/min, stays under Gemini 15/min free tier)
//   maxConcurrentDispatches: 1
//   maxAttempts: 5
//   minBackoff: 60s
//   maxBackoff: 300s

"use strict";

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");
const {createPrayerWallServices} = require("../service_locator");

/**
 * Firestore trigger: on_prayer_submitted
 * Fires whenever a new document is created in `prayers/{prayerId}`.
 *
 * Services are constructed via the DI factory (createPrayerWallServices) so
 * they can be injected/mocked in tests without modifying this handler.
 */
const onPrayerSubmitted = onDocumentCreated(
  "prayers/{prayerId}",
  async (event) => {
    const prayerId = event.params.prayerId;
    const prayer = event.data?.data();

    if (!prayer) {
      logger.warn(`[onPrayerSubmitted] No data for prayer ${prayerId}`);
      return;
    }

    const db = admin.firestore();
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

    let maskedText = prayer.originalText || "";
    const language = prayer.language || "en";

    // Step 1: PII Masking (synchronous — must complete before prayer is ever shown)
    let piiResult;
    try {
      piiResult = await piiService.mask(maskedText, language);
      maskedText = piiResult.maskedText;

      logger.info(
        `[onPrayerSubmitted] PII masking complete for ${prayerId} ` +
        `(modified: ${piiResult.wasModified})`,
      );
    } catch (err) {
      logger.error(
        `[onPrayerSubmitted] PII masking failed for ${prayerId}: ${err.message}`,
      );
      // Continue to moderation — prayer stays pending until manually resolved.
      piiResult = {maskedText, wasModified: false};
    }

    // Step 2: Moderation
    let moderationResult;
    try {
      // Get moderation result without writing to Firestore yet
      const ref = db.collection("prayers").doc(prayerId);
      const snapshot = await ref.get();

      if (!snapshot.exists) {
        logger.warn(`[onPrayerSubmitted] Prayer ${prayerId} not found — skipped`);
        return;
      }

      const text = maskedText;
      moderationResult = await moderationService.moderate(text, language);

      // Determine status from moderation result
      const status = moderationResult.isPastoral ? "pastoral" :
                     moderationResult.approved ? "approved" :
                     moderationResult.confidence < 0.75 ? "needs_review" :
                     "rejected";

      // Single merged write with all fields from both PII masking and moderation
      await ref.update({
        maskedText,
        originalText: admin.firestore.FieldValue.delete(), // remove from doc
        piiMasked: true,
        piiWasModified: piiResult.wasModified,
        status,
        moderationScore: moderationResult.confidence,
        moderationFlag: moderationResult.flag,
        moderationReason: moderationResult.reason,
        moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(
        `[onPrayerSubmitted] Prayer ${prayerId} processed ` +
        `(piiModified: ${piiResult.wasModified}, status: ${status}, ` +
        `flag: ${moderationResult.flag}, confidence: ${moderationResult.confidence})`,
      );
    } catch (err) {
      // RATE_LIMIT or other transient error: write PII masking results only
      logger.warn(
        `[onPrayerSubmitted] Moderation failed for ${prayerId}: ${err.message}`,
      );

      // Fallback: write only PII masking results if moderation fails
      await db.collection("prayers").doc(prayerId).update({
        maskedText,
        originalText: admin.firestore.FieldValue.delete(),
        piiMasked: true,
        piiWasModified: piiResult.wasModified,
      });
    }
  },
);

module.exports = {onPrayerSubmitted};

