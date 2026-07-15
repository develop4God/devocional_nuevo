// functions/service_locator.js
// Dependency Injection factory for Prayer Wall Cloud Functions.
// Keeps service construction out of the trigger handler so providers can be
// swapped (e.g. for testing) without touching trigger logic.

"use strict";

const {GeminiPiiMaskingService} = require("./services/gemini_pii_masking_service");
const {GeminiModerationService} = require("./services/gemini_moderation_service");
const {createModerationQueueHandler} = require("./tasks/moderation_queue_handler");

/**
 * Default fetch function — Node 22 (this project's declared engine, see
 * functions/package.json) has a global `fetch`, so no dependency is needed.
 *
 * F-11 follow-up (found by adversarial validation, 2026-07-15): this
 * previously dynamically imported "node-fetch", which is NOT listed in
 * functions/package.json's dependencies — it only resolved because a
 * transitive dependency happened to hoist a copy into node_modules. F-11's
 * fix makes this code path actually run in production for the first time,
 * which would have made that latent fragility live too (an `npm ci` that
 * doesn't happen to hoist node-fetch would break the whole pipeline with a
 * module-not-found error). Using the runtime's built-in fetch removes the
 * dependency entirely instead of just declaring it.
 * @returns {Function}
 */
function defaultFetchFn() {
  return (...args) => fetch(...args);
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
