// functions/service_locator.js
// Dependency Injection factory for Prayer Wall Cloud Functions.
// Keeps service construction out of the trigger handler so providers can be
// swapped (e.g. for testing) without touching trigger logic.

"use strict";

const {GeminiPiiMaskingService} = require("./services/gemini_pii_masking_service");
const {GeminiModerationService} = require("./services/gemini_moderation_service");
const {createModerationQueueHandler} = require("./tasks/moderation_queue_handler");

/**
 * Default fetch function — uses node-fetch (dynamic import for ESM compat).
 * @returns {Function}
 */
function defaultFetchFn() {
  return (...args) => import("node-fetch").then((m) => m.default(...args));
}

/**
 * Creates the services required by the prayer-wall pipeline.
 *
 * @param {Object} opts
 * @param {string}   opts.apiKey       - Gemini API key.
 * @param {Function} [opts.fetchFn]    - HTTP fetch function (injectable for testing).
 * @param {Object}   opts.db           - Firestore Admin instance.
 * @param {Object}   opts.logger       - Firebase logger.
 * @returns {{ piiService, moderationService, moderationHandler }}
 */
function createPrayerWallServices({apiKey, fetchFn, db, logger}) {
  const fetch = fetchFn ?? defaultFetchFn();

  const piiService = new GeminiPiiMaskingService({fetchFn: fetch, apiKey});
  const moderationService = new GeminiModerationService({fetchFn: fetch, apiKey});
  const moderationHandler = createModerationQueueHandler({
    moderationService,
    db,
    logger,
  });

  return {piiService, moderationService, moderationHandler};
}

module.exports = {createPrayerWallServices};
