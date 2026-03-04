// functions/tasks/moderation_queue_handler.js
// Handles moderation tasks dispatched from the Cloud Tasks queue.
// Rate limit strategy: maxDispatchesPerSecond=0.2 (12/min, under 15/min Gemini free tier).

"use strict";

/**
 * @param {Object} opts
 * @param {import('../services/i_moderation_service').IModerationService} opts.moderationService
 * @param {import('firebase-admin').firestore.Firestore} opts.db
 * @param {Object} opts.logger
 */
function createModerationQueueHandler({moderationService, db, logger}) {
  /**
   * Process a single prayer moderation task.
   * @param {string} prayerId
   */
  async function handle(prayerId) {
    const ref = db.collection("prayers").doc(prayerId);
    const snapshot = await ref.get();

    // EC-006: Prayer deleted before moderation ran → drop task silently
    if (!snapshot.exists) {
      logger.warn(`[ModerationQueue] Prayer ${prayerId} not found — skipped`);
      return;
    }

    const prayer = snapshot.data();
    const text = prayer.maskedText || prayer.originalText || "";
    const language = prayer.language || "en";

    let result;
    try {
      result = await moderationService.moderate(text, language);
    } catch (err) {
      if (err.message === "RATE_LIMIT") {
        // Cloud Tasks will retry with exponential backoff — re-throw to signal failure
        logger.warn(`[ModerationQueue] Rate limit hit for ${prayerId} — will retry`);
        throw err;
      }
      // Other errors: route to needs_review instead of crashing
      logger.error(`[ModerationQueue] Moderation error for ${prayerId}: ${err.message}`);
      result = {
        approved: false,
        confidence: 0.0,
        flag: "none",
        reason: `Moderation error: ${err.message}`,
        isPastoral: false,
      };
    }

    const status = resolveStatus(result);

    await ref.update({
      status,
      moderationScore: result.confidence,
      moderationFlag: result.flag,
      moderationReason: result.reason,
      moderatedAt: db.constructor.FieldValue?.serverTimestamp?.() ??
        require("firebase-admin").firestore.FieldValue.serverTimestamp(),
    });

    logger.info(
      `[ModerationQueue] Prayer ${prayerId} → status: ${status} ` +
      `(flag: ${result.flag}, confidence: ${result.confidence})`,
    );
  }

  return {handle};
}

/**
 * Determines the Firestore status string from a moderation result.
 * @param {import('../services/i_moderation_service').ModerationResult} result
 * @returns {string}
 */
function resolveStatus(result) {
  if (result.isPastoral) return "pastoral";
  if (result.approved) return "approved";
  if (result.confidence < 0.75) return "needs_review"; // Low confidence → human review
  return "rejected";
}

module.exports = {createModerationQueueHandler, resolveStatus};
