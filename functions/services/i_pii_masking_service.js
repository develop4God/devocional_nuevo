// functions/services/i_pii_masking_service.js
// Interface (duck-typed contract) for PII masking services.
// Implement this contract to swap providers without touching Cloud Function logic.

/**
 * @typedef {Object} PiiMaskingResult
 * @property {string} maskedText   - PII-free version safe to display publicly.
 * @property {boolean} wasModified - true if any PII was found and masked.
 */

/**
 * IPiiMaskingService contract.
 * Implementations must provide a `mask(text, language)` method.
 *
 * @abstract
 */
class IPiiMaskingService {
  /**
   * Mask personally identifiable information from prayer text.
   * Preserves spiritual content, emotional language, and cultural expressions.
   *
   * @param {string} text     - Raw prayer text (may contain PII).
   * @param {string} language - BCP-47 language code: en|es|pt|fr|hi|ja|zh
   * @returns {Promise<PiiMaskingResult>}
   */
  // eslint-disable-next-line no-unused-vars
  async mask(text, language) {
    throw new Error("IPiiMaskingService.mask() must be implemented");
  }
}

module.exports = {IPiiMaskingService};
