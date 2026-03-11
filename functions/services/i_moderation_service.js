// functions/services/i_moderation_service.js
// Interface (duck-typed contract) for content moderation services.

"use strict";

/**
 * @typedef {Object} ModerationResult
 * @property {boolean} approved     - true if prayer is appropriate to show publicly.
 * @property {number}  confidence   - 0.0–1.0 confidence score.
 * @property {string}  flag         - "none"|"spam"|"hate"|"sexual"|"self_harm"
 * @property {string}  reason       - Internal reason (never shown to user).
 * @property {boolean} isPastoral   - true when self_harm: triggers pastoral response, not rejection.
 */

/**
 * IModerationService contract.
 */
class IModerationService {
  /**
   * Moderate prayer text in its original language.
   * NEVER translates first.
   *
   * @param {string} text     - PII-masked prayer text.
   * @param {string} language - BCP-47 language code.
   * @returns {Promise<ModerationResult>}
   */
  // eslint-disable-next-line no-unused-vars
  async moderate(text, language) {
    throw new Error("IModerationService.moderate() must be implemented");
  }
}

module.exports = {IModerationService};
