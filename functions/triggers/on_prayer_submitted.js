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
    const {piiService, moderationHandler} = createPrayerWallServices({
      apiKey: geminiApiKey,
      db,
      logger,
    });

    let maskedText = prayer.originalText || "";
    const language = prayer.language || "en";

    // Step 1: PII Masking (synchronous — must complete before prayer is ever shown)
    try {
      const piiResult = await piiService.mask(maskedText, language);
      maskedText = piiResult.maskedText;

      // Store maskedText and CLEAR originalText so approved documents never
      // expose raw user text to authenticated clients (AC-002, EC-010).
      await db.collection("prayers").doc(prayerId).update({
        maskedText,
        originalText: admin.firestore.FieldValue.delete(), // remove from doc
        piiMasked: true,
        piiWasModified: piiResult.wasModified,
      });

      logger.info(
        `[onPrayerSubmitted] PII masking complete for ${prayerId} ` +
        `(modified: ${piiResult.wasModified})`,
      );
    } catch (err) {
      logger.error(
        `[onPrayerSubmitted] PII masking failed for ${prayerId}: ${err.message}`,
      );
      // Continue to moderation — prayer stays pending until manually resolved.
    }

    // Step 2: Moderation via injected handler
    try {
      await moderationHandler.handle(prayerId);
    } catch (err) {
      // RATE_LIMIT or other transient error: prayer stays "pending".
      // A Cloud Tasks retry would pick this up in a queue-based setup.
      logger.warn(
        `[onPrayerSubmitted] Moderation deferred for ${prayerId}: ${err.message}`,
      );
    }
  },
);

module.exports = {onPrayerSubmitted};

