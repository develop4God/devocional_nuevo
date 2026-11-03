// Emulator tests for ../../firestore.rules
// Run: npm test   (starts the Firestore emulator via firebase-tools)
// Set RULES_PATH to test a different rules file.
const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  deleteDoc,
  addDoc,
  collection,
} = require('firebase/firestore');

const RULES_PATH =
  process.env.RULES_PATH || path.join(__dirname, '../../firestore.rules');

const ALICE = 'alice-uid';
const BOB = 'bob-uid';
const TOKEN = 'fcm-token-1';

let env;

// The app signs users in anonymously (lib/main.dart), so the primary
// identity under test is an anonymous Firebase Auth user.
const anonymous = (uid) =>
  env
    .authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } })
    .firestore();
const signedOut = () => env.unauthenticatedContext().firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-devocional',
    firestore: { rules: fs.readFileSync(RULES_PATH, 'utf8') },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

// ── P0: anonymous user notification flow ─────────────────────────────────────

test('anonymous owner can save their FCM token', async () => {
  const db = anonymous(ALICE);
  await assertSucceeds(
    setDoc(
      doc(db, `users/${ALICE}/fcmTokens/${TOKEN}`),
      { token: TOKEN, platform: 'android' },
      { merge: true },
    ),
  );
});

test('anonymous owner can write and read notification settings', async () => {
  const db = anonymous(ALICE);
  const ref = doc(db, `users/${ALICE}/settings/notifications`);
  await assertSucceeds(setDoc(ref, { notificationsEnabled: true }, { merge: true }));
  await assertSucceeds(getDoc(ref));
});

test('anonymous owner can update lastLogin on their user document', async () => {
  const db = anonymous(ALICE);
  await assertSucceeds(
    setDoc(doc(db, `users/${ALICE}`), { lastLogin: 1 }, { merge: true }),
  );
});

// ── Negative: other users, signed-out, unknown paths ─────────────────────────

test('a different user cannot write or read another user FCM token', async () => {
  await seed((db) =>
    setDoc(doc(db, `users/${ALICE}/fcmTokens/${TOKEN}`), { token: TOKEN }),
  );
  const db = anonymous(BOB);
  const ref = doc(db, `users/${ALICE}/fcmTokens/${TOKEN}`);
  await assertFails(setDoc(ref, { token: 'hijack' }));
  await assertFails(getDoc(ref));
});

test('a different user cannot touch another user settings or document', async () => {
  const db = anonymous(BOB);
  await assertFails(setDoc(doc(db, `users/${ALICE}/settings/notifications`), { a: 1 }));
  await assertFails(getDoc(doc(db, `users/${ALICE}/settings/notifications`)));
  await assertFails(setDoc(doc(db, `users/${ALICE}`), { a: 1 }));
  await assertFails(getDoc(doc(db, `users/${ALICE}`)));
});

test('signed-out clients cannot read or write user data', async () => {
  const db = signedOut();
  await assertFails(setDoc(doc(db, `users/${ALICE}/fcmTokens/${TOKEN}`), { token: TOKEN }));
  await assertFails(getDoc(doc(db, `users/${ALICE}/settings/notifications`)));
  await assertFails(setDoc(doc(db, `users/${ALICE}`), { a: 1 }));
});

test('the owner cannot write to an unknown subcollection of their document', async () => {
  const db = anonymous(ALICE);
  await assertFails(setDoc(doc(db, `users/${ALICE}/unknown/x`), { a: 1 }));
});

test('unknown top-level collections are denied for authenticated users', async () => {
  const db = anonymous(ALICE);
  await assertFails(setDoc(doc(db, 'other/x'), { a: 1 }));
  await assertFails(getDoc(doc(db, 'other/x')));
});

// ── Prayer Wall is closed ────────────────────────────────────────────────────

test('prayer wall: authenticated users cannot read an approved prayer', async () => {
  await seed((db) =>
    setDoc(doc(db, 'prayers/p1'), { status: 'approved', ownerUid: ALICE }),
  );
  await assertFails(getDoc(doc(anonymous(BOB), 'prayers/p1')));
});

test('prayer wall: authenticated users cannot create a prayer', async () => {
  const db = anonymous(ALICE);
  await assertFails(addDoc(collection(db, 'prayers'), { status: 'pending', ownerUid: ALICE }));
});

test('prayer wall: a client cannot self-approve a prayer on create', async () => {
  const db = anonymous(ALICE);
  await assertFails(setDoc(doc(db, 'prayers/p2'), { status: 'approved', ownerUid: ALICE }));
});

test('prayer wall: the owner cannot delete their own prayer', async () => {
  await seed((db) =>
    setDoc(doc(db, 'prayers/p3'), { status: 'approved', ownerUid: ALICE }),
  );
  await assertFails(deleteDoc(doc(anonymous(ALICE), 'prayers/p3')));
});

test('prayer wall: signed-out clients cannot read prayers', async () => {
  await seed((db) =>
    setDoc(doc(db, 'prayers/p4'), { status: 'approved', ownerUid: ALICE }),
  );
  await assertFails(getDoc(doc(signedOut(), 'prayers/p4')));
});
