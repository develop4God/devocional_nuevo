// index.js - Cloud Functions optimizadas para notificaciones y limpieza

const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const {logger} = require("firebase-functions");
const {setGlobalOptions} = require("firebase-functions/v2");
const {DateTime} = require("luxon");

// --- Traducciones para notificaciones multiidioma ---
const NOTIFICATION_TRANSLATIONS = {
  es: {
    title: "Tu espacio de Paz te espera",
    body: "¡Recuerda conectarte hoy con la palabra de Dios!",
  },
  en: {
    title: "Your Peace Space is waiting",
    body: "Remember to connect today with the word of God!",
  },
  pt: {
    title: "Seu espaço de Paz te espera",
    body: "Lembre-se de se conectar hoje com a palavra de Deus!",
  },
  fr: {
    title: "Votre espace de Paix vous attend",
    body: "N'oubliez pas de vous connecter aujourd'hui avec la parole de Dieu!",
  },
};

const NOTIFICATION_IMAGE_URL = "https://cdn.jsdelivr.net/gh/develop4God/Devocional_nuevo@main/assets/images/notification_images/cross_sky_400x200.jpg";

// Configuración global
setGlobalOptions({region: "us-central1"});

// Inicialización de Firebase Admin
logger.info("Cloud Function: Iniciando inicialización.", {structuredData: true});

try {
  if (!admin.apps.length) {
    admin.initializeApp();
    logger.info("Cloud Function: Firebase Admin SDK inicializado.", {structuredData: true});
  }
} catch (e) {
  logger.error("Cloud Function: Error en inicialización:", e, {structuredData: true});
  throw e;
}

const db = admin.firestore();

// Helper: Seleccionar idioma
function selectLanguageForUser(preferredLanguage) {
  return (preferredLanguage && NOTIFICATION_TRANSLATIONS[preferredLanguage]) ?
        preferredLanguage :
        "es";
}

// ==========================================
// FUNCIÓN 1: ENVIAR NOTIFICACIONES DIARIAS
// ==========================================
exports.sendDailyDevotionalNotification = onSchedule({
  schedule: "0 * * * *",
  timeZone: "UTC",
}, async (context) => {
  logger.info("Notificaciones: Ejecución iniciada.", {structuredData: true});

  const usersRef = db.collection("users");
  const usersSnapshot = await usersRef.get();

  if (usersSnapshot.empty) {
    logger.info("Notificaciones: Sin usuarios.", {structuredData: true});
    return null;
  }

  const nowUtc = DateTime.now().setZone("UTC");
  logger.info(`Notificaciones: ${usersSnapshot.size} usuarios. Hora UTC: ${nowUtc.toFormat("HH:mm")}.`, {structuredData: true});

  for (const userDoc of usersSnapshot.docs) {
    const userId = userDoc.id;

    const settingsRef = db.collection("users").doc(userId).collection("settings").doc("notifications");
    let settingsDoc;

    try {
      settingsDoc = await settingsRef.get();
    } catch (e) {
      logger.error(`Notificaciones: Error al obtener settings de ${userId}.`, {structuredData: true});
      continue;
    }

    if (!settingsDoc.exists) {
      continue;
    }

    const settingsData = settingsDoc.data();
    const {notificationsEnabled, notificationTime, userTimezone, preferredLanguage, lastNotificationSentDate} = settingsData;

    if (!notificationsEnabled || !userTimezone || !notificationTime) {
      continue;
    }

    let userLocalTime;
    try {
      if (!DateTime.local().setZone(userTimezone).isValid) {
        logger.warn(`Notificaciones: Timezone inválido ${userId}: ${userTimezone}.`, {structuredData: true});
        continue;
      }
      userLocalTime = nowUtc.setZone(userTimezone);
    } catch (e) {
      logger.error(`Notificaciones: Error timezone ${userId}.`, {structuredData: true});
      continue;
    }

    const [preferredHour, preferredMinute] = notificationTime.split(":").map(Number);
    if (isNaN(preferredHour) || isNaN(preferredMinute)) {
      logger.warn(`Notificaciones: Hora inválida ${userId}: ${notificationTime}.`, {structuredData: true});
      continue;
    }

    const todayInUserTimezone = userLocalTime.toISODate();
    let lastSentDate = null;

    if (lastNotificationSentDate instanceof admin.firestore.Timestamp) {
      lastSentDate = DateTime.fromJSDate(lastNotificationSentDate.toDate(), {zone: userTimezone}).toISODate();
    } else if (typeof lastNotificationSentDate === "string") {
      lastSentDate = lastNotificationSentDate;
    }

    const isTimeToSend = (userLocalTime.hour === preferredHour);
    const alreadySentToday = (lastSentDate === todayInUserTimezone);

    if (!isTimeToSend || alreadySentToday) {
      continue;
    }

    logger.info(`Notificaciones: Usuario ${userId} elegible. Obteniendo tokens.`, {structuredData: true});
    const fcmTokensSnapshot = await db.collection("users").doc(userId).collection("fcmTokens").get();

    if (fcmTokensSnapshot.empty) {
      logger.warn(`Notificaciones: Sin tokens FCM para ${userId}.`, {structuredData: true});
      continue;
    }

    const tokens = fcmTokensSnapshot.docs.map((doc) => doc.data().token).filter((t) => t);

    if (tokens.length === 0) {
      continue;
    }

    const userLanguage = selectLanguageForUser(preferredLanguage);
    const userTranslations = NOTIFICATION_TRANSLATIONS[userLanguage];

    const message = {
      notification: {
        title: userTranslations.title,
        body: userTranslations.body,
      },
      data: {
        userId: userId,
        notificationType: "daily_devotional",
        language: userLanguage,
      },
      android: {
        notification: {
          imageUrl: NOTIFICATION_IMAGE_URL,
        },
      },
      apns: {
        payload: {
          aps: {
            "mutable-content": 1,
          },
        },
        fcm_options: {
          image: NOTIFICATION_IMAGE_URL,
        },
      },
      tokens: tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    logger.info(`Notificaciones: Enviadas a ${response.successCount}/${tokens.length} dispositivos (${userId}, ${userLanguage}).`, {structuredData: true});

    await settingsRef.update({
      lastNotificationSentDate: admin.firestore.Timestamp.fromDate(userLocalTime.toJSDate()),
    });

    if (response.failureCount > 0) {
      response.responses.forEach(async (resp, idx) => {
        if (!resp.success && (resp.error?.code === "messaging/invalid-argument" || resp.error?.code === "messaging/registration-token-not-registered")) {
          const invalidToken = tokens[idx];
          logger.warn(`Notificaciones: Eliminando token inválido de ${userId}.`, {structuredData: true});

          const tokenQuery = await db.collection("users").doc(userId).collection("fcmTokens")
              .where("token", "==", invalidToken)
              .get();

          tokenQuery.docs.forEach(async (doc) => {
            await doc.ref.delete();
          });
        }
      });
    }
  }

  logger.info("Notificaciones: Ejecución finalizada.", {structuredData: true});
  return null;
});

// ==========================================
// FUNCIÓN 2: LIMPIEZA DE BASE DE DATOS
// ==========================================
exports.cleanupInvalidFCMTokens = onSchedule({
  schedule: "every 24 hours",
  timeZone: "UTC",
  timeoutSeconds: 540,
  memory: "512MiB",
}, async (context) => {
  logger.info("Limpieza: Iniciando proceso.", {structuredData: true});

  const now = admin.firestore.Timestamp.now();
  const sevenDaysAgo = admin.firestore.Timestamp.fromMillis(now.toMillis() - (7 * 24 * 60 * 60 * 1000));
  const thirtyDaysAgo = admin.firestore.Timestamp.fromMillis(now.toMillis() - (30 * 24 * 60 * 60 * 1000));

  let deletedUsers = 0;
  let deletedTokens = 0;
  let validatedTokens = 0;

  try {
    // FASE 1: Eliminar usuarios inactivos
    logger.info("Limpieza: Fase 1 - Buscando usuarios inactivos.", {structuredData: true});

    const usersSnapshot = await db.collection("users").get();
    const batch = db.batch();
    let batchCount = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const settingsRef = db.collection("users").doc(userId).collection("settings").doc("notifications");

      let settingsDoc;
      try {
        settingsDoc = await settingsRef.get();
      } catch (e) {
        continue;
      }

      if (!settingsDoc.exists) {
        continue;
      }

      const settingsData = settingsDoc.data();
      const lastUpdated = settingsData.lastUpdated;

      if (!lastUpdated || (lastUpdated instanceof admin.firestore.Timestamp && lastUpdated.toMillis() < sevenDaysAgo.toMillis())) {
        logger.info(`Limpieza: Usuario inactivo ${userId}. Eliminando.`, {structuredData: true});

        const tokensSnapshot = await db.collection("users").doc(userId).collection("fcmTokens").get();
        tokensSnapshot.docs.forEach((tokenDoc) => {
          batch.delete(tokenDoc.ref);
          batchCount++;
          deletedTokens++;
        });

        batch.delete(settingsRef);
        batchCount++;
        deletedUsers++;

        if (batchCount >= 450) {
          await batch.commit();
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    logger.info(`Limpieza: Fase 1 completada. ${deletedUsers} usuarios eliminados.`, {structuredData: true});

    // FASE 2: Eliminar tokens antiguos
    logger.info("Limpieza: Fase 2 - Limpiando tokens antiguos.", {structuredData: true});

    const activeUsersSnapshot = await db.collection("users").get();
    const tokenBatch = db.batch();
    let tokenBatchCount = 0;

    for (const userDoc of activeUsersSnapshot.docs) {
      const userId = userDoc.id;
      const tokensSnapshot = await db.collection("users").doc(userId).collection("fcmTokens").get();

      for (const tokenDoc of tokensSnapshot.docs) {
        const tokenData = tokenDoc.data();
        const createdAt = tokenData.createdAt;

        if (createdAt instanceof admin.firestore.Timestamp && createdAt.toMillis() < thirtyDaysAgo.toMillis()) {
          logger.info(`Limpieza: Token antiguo de ${userId}. Eliminando.`, {structuredData: true});
          tokenBatch.delete(tokenDoc.ref);
          tokenBatchCount++;
          deletedTokens++;

          if (tokenBatchCount >= 450) {
            await tokenBatch.commit();
            tokenBatchCount = 0;
          }
        }
      }
    }

    if (tokenBatchCount > 0) {
      await tokenBatch.commit();
    }

    logger.info(`Limpieza: Fase 2 completada. ${deletedTokens - deletedUsers} tokens antiguos eliminados.`, {structuredData: true});

    // FASE 3: Validar tokens con FCM
    logger.info("Limpieza: Fase 3 - Validando tokens con FCM.", {structuredData: true});

    const allTokensToValidate = [];
    const finalUsersSnapshot = await db.collection("users").get();

    for (const userDoc of finalUsersSnapshot.docs) {
      const userId = userDoc.id;
      const tokensSnapshot = await db.collection("users").doc(userId).collection("fcmTokens").get();

      tokensSnapshot.docs.forEach((tokenDoc) => {
        const tokenData = tokenDoc.data();
        if (tokenData.token) {
          allTokensToValidate.push({
            token: tokenData.token,
            userId: userId,
            ref: tokenDoc.ref,
          });
        }
      });
    }

    if (allTokensToValidate.length === 0) {
      logger.info("Limpieza: Sin tokens para validar.", {structuredData: true});
    } else {
      logger.info(`Limpieza: Validando ${allTokensToValidate.length} tokens.`, {structuredData: true});

      for (let i = 0; i < allTokensToValidate.length; i += 500) {
        const chunk = allTokensToValidate.slice(i, i + 500);
        const tokens = chunk.map((t) => t.token);

        const message = {
          data: {
            type: "cleanup_check",
            timestamp: new Date().toISOString(),
          },
          tokens: tokens,
        };

        try {
          const response = await admin.messaging().sendEachForMulticast(message);
          validatedTokens += response.successCount;

          const invalidBatch = db.batch();
          let invalidBatchCount = 0;

          response.responses.forEach((resp, index) => {
            if (!resp.success) {
              const tokenInfo = chunk[index];
              logger.warn(`Limpieza: Token inválido (${tokenInfo.userId}). Eliminando.`, {structuredData: true});
              invalidBatch.delete(tokenInfo.ref);
              invalidBatchCount++;
              deletedTokens++;
            }
          });

          if (invalidBatchCount > 0) {
            await invalidBatch.commit();
          }
        } catch (error) {
          logger.error("Limpieza: Error al validar chunk:", error, {structuredData: true});
        }
      }

      logger.info(`Limpieza: Fase 3 completada. ${validatedTokens} tokens válidos.`, {structuredData: true});
    }

    logger.info(`Limpieza: Completado. ${deletedUsers} usuarios, ${deletedTokens} tokens eliminados.`, {structuredData: true});
  } catch (error) {
    logger.error("Limpieza: Error general:", error, {structuredData: true});
  }

  return null;
});
