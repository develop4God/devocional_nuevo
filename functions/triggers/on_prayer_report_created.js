// functions/triggers/on_prayer_report_created.js
// Firestore trigger: fires when a user reports a prayer.
//
// SECURITY_ASSESSMENT F-06: the client used to increment `reportCount`
// directly, which let a single user call reportPrayer() three times and
// force any prayer into needs_review — a one-account takedown. Reports are
// now written to prayers/{prayerId}/reports/{reporterId} (one doc per user,
// enforced by the Firestore rule requiring the doc ID to equal
// request.auth.uid; a second report from the same user hits `allow update:
// if false` and is rejected). This trigger is the only writer of
// `reportCount` on the parent prayer, so the count reflects distinct
// reporters only.

"use strict";

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");

const REPORT_THRESHOLD = 3;

const onPrayerReportCreated = onDocumentCreated(
    "prayers/{prayerId}/reports/{reporterId}",
    async (event) => {
      const {prayerId, reporterId} = event.params;
      const db = admin.firestore();
      const prayerRef = db.collection("prayers").doc(prayerId);

      await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(prayerRef);

        if (!snapshot.exists) {
          logger.warn(`[onPrayerReportCreated] Prayer ${prayerId} not found — skipped`);
          return;
        }

        const prayer = snapshot.data();

        if (prayer.status !== "approved") {
          // Prayer already left the public wall (rejected, needs_review,
          // pastoral, deleted-and-recreated with the same id never happens
          // since ids are auto-generated) — a stray/late report shouldn't
          // resurrect or double-flag it.
          logger.info(
              `[onPrayerReportCreated] Prayer ${prayerId} not approved (status: ${prayer.status}) — report ignored`,
          );
          return;
        }

        const newReportCount = (prayer.reportCount || 0) + 1;
        const updates = {reportCount: newReportCount};

        if (newReportCount >= REPORT_THRESHOLD) {
          updates.status = "needs_review";
        }

        transaction.update(prayerRef, updates);
      });

      logger.info(
          `[onPrayerReportCreated] Report from ${reporterId} recorded for prayer ${prayerId}`,
      );
    },
);

module.exports = {onPrayerReportCreated, REPORT_THRESHOLD};
