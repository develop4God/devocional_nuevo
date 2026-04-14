// index.js - Cloud Functions optimizadas para notificaciones y limpieza

const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const {logger} = require("firebase-functions");
const {setGlobalOptions} = require("firebase-functions/v2");
const {DateTime} = require("luxon");

// --- Traducciones para notificaciones multiidioma ---
// Each language has an array of variants; one is chosen randomly at send time.
// Option A — Peace space (original)
// Option B — Daily habit: devotional waiting
// Option C — Encounter: God has something for you
// Option D — Daily habit: have you spent time with God?
const NOTIFICATION_TRANSLATIONS = {
  es: [
    {
      // Option A — Peace space (original)
      title: "Tu espacio de Paz te espera",
      body: "¡Recuerda conectarte hoy con la palabra de Dios!",
    },
    {
      // Option B — Daily habit
      title: "Tu devocional te espera",
      body: "Empieza el día con la Palabra de Dios.",
    },
    {
      // Option C — Encounter
      title: "Dios tiene algo para ti hoy",
      body: "Abre tu devocional y descúbrelo.",
    },
    {
      // Option D — Daily habit
      title: "¿Ya pasaste tiempo con Dios hoy?",
      body: "Tu devocional está listo para ti.",
    },
  ],
  en: [
    {
      // Option A — Peace space (original)
      title: "Your Peace Space is waiting",
      body: "Remember to connect today with the word of God!",
    },
    {
      // Option B — Daily habit
      title: "Your devotional is waiting for you",
      body: "Start the day with the Word of God.",
    },
    {
      // Option C — Encounter
      title: "God has something for you today",
      body: "Open your devotional and discover it.",
    },
    {
      // Option D — Daily habit
      title: "Have you spent time with God today?",
      body: "Your devotional is ready for you.",
    },
  ],
  pt: [
    {
      // Option A — Peace space (original)
      title: "Seu espaço de Paz te espera",
      body: "Lembre-se de se conectar hoje com a palavra de Deus!",
    },
    {
      // Option B — Daily habit
      title: "Seu devocional está esperando por você",
      body: "Comece o dia com a Palavra de Deus.",
    },
    {
      // Option C — Encounter
      title: "Deus tem algo para você hoje",
      body: "Abra seu devocional e descubra.",
    },
    {
      // Option D — Daily habit
      title: "Você já passou um tempo com Deus hoje?",
      body: "Seu devocional está pronto para você.",
    },
  ],
  fr: [
    {
      // Option A — Peace space (original)
      title: "Votre espace de Paix vous attend",
      body: "N'oubliez pas de vous connecter aujourd'hui avec la parole de Dieu!",
    },
    {
      // Option B — Daily habit
      title: "Votre dévotionnel vous attend",
      body: "Commencez la journée avec la Parole de Dieu.",
    },
    {
      // Option C — Encounter
      title: "Dieu a quelque chose pour vous aujourd'hui",
      body: "Ouvrez votre dévotionnel et découvrez-le.",
    },
    {
      // Option D — Daily habit
      title: "Avez-vous passé du temps avec Dieu aujourd'hui ?",
      body: "Votre dévotionnel est prêt pour vous.",
    },
  ],
  ja: [
    {
      // Option A — Peace space (original)
      title: "あなたの平和の空間が待っています",
      body: "今日、神の言葉とつながることを忘れないでください！",
    },
    {
      // Option B — Daily habit
      title: "あなたのデボーショナルがあなたを待っています",
      body: "神の言葉で一日を始めましょう。",
    },
    {
      // Option C — Encounter
      title: "今日、神があなたのために何かをお持ちです",
      body: "デボーショナルを開いて、それを発見してください。",
    },
    {
      // Option D — Daily habit
      title: "今日、神と時間を過ごしましたか？",
      body: "あなたのデボーショナルが準備できています。",
    },
  ],
  zh: [
    {
      // Option A — Peace space (original)
      title: "你的平安空间在等待",
      body: "记得今天与神的话语连接！",
    },
    {
      // Option B — Daily habit
      title: "你的灵修在等你",
      body: "用神的话语开始新的一天。",
    },
    {
      // Option C — Encounter
      title: "上帝今天为你准备了一些东西",
      body: "打开你的灵修，去发现它。",
    },
    {
      // Option D — Daily habit
      title: "你今天和上帝在一起了吗？",
      body: "你的灵修已经为你准备好了。",
    },
  ],
  hi: [
    {
      // Option A — Peace space (original)
      title: "आपकी शांति का स्थान प्रतीक्षा कर रहा है",
      body: "आज परमेश्वर के वचन से जुड़ना याद रखें!",
    },
    {
      // Option B — Daily habit
      title: "आपका भक्तिपाठ आपका इंतजार कर रहा है",
      body: "परमेश्वर के वचन के साथ दिन की शुरुआत करें।",
    },
    {
      // Option C — Encounter
      title: "आज परमेश्वर के पास आपके लिए कुछ है",
      body: "अपना भक्तिपाठ खोलें और इसे जानें।",
    },
    {
      // Option D — Daily habit
      title: "क्या आपने आज परमेश्वर के साथ समय बिताया?",
      body: "आपका भक्तिपाठ आपके लिए तैयार है।",
    },
  ],
  ar: [
    {
      // Option A — Peace space (original)
      title: "مساحة سلامك في انتظارك",
      body: "تذكر أن تتواصل اليوم مع كلمة الله!",
    },
    {
      // Option B — Daily habit
      title: "دروسك الإيمانية تنتظرك",
      body: "ابدأ يومك بكلمة الله.",
    },
    {
      // Option C — Encounter
      title: "لدى الله شيء لك اليوم",
      body: "افتح كتاب تأملاتك واكتشفه.",
    },
    {
      // Option D — Daily habit
      title: "هل أمضيت وقتًا مع الله اليوم؟",
      body: "دروسك الإيمانية جاهزة لك.",
    },
  ],
};

const NOTIFICATION_IMAGES = [
  "blue_mountains.avif",
  "circle_grass_green.avif",
  "desert_person.avif",
  "desert_view_rocks.avif",
  "grass_tree.avif",
  "gray_dock_lake.avif",
  "lake.avif",
  "lake_colors.avif",
  "lake_dock.avif",
  "long_road.avif",
  "mountain_pink.avif",
  "river_rocks_trees.avif",
  "road_green_montains.avif",
  "rocks_beach.avif",
].map((name) => `https://raw.githubusercontent.com/develop4God/Devocionales-assets/refs/heads/main/images/habitus/${name}`);

function getRandomNotificationImage() {
  return NOTIFICATION_IMAGES[Math.floor(Math.random() * NOTIFICATION_IMAGES.length)];
}

/**
 * Returns a random {title, body} variant for the given language.
 * Falls back to "es" if the language is not found.
 */
function getRandomTranslation(language) {
  const variants = NOTIFICATION_TRANSLATIONS[language] || NOTIFICATION_TRANSLATIONS["es"];
  return variants[Math.floor(Math.random() * variants.length)];
}

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
    const userTranslation = getRandomTranslation(userLanguage);
    const notificationImage = getRandomNotificationImage();

    const message = {
      notification: {
        title: userTranslation.title,
        body: userTranslation.body,
      },
      data: {
        userId: userId,
        notificationType: "daily_devotional",
        language: userLanguage,
      },
      android: {
        notification: {
          imageUrl: notificationImage,
        },
      },
      apns: {
        payload: {
          aps: {
            "mutable-content": 1,
          },
        },
        fcm_options: {
          image: notificationImage,
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
// FUNCIÓN 2: LIMPIEZA AGRESIVA DE BASE DE DATOS
// Elimina usuario completo si cumple cualquier condición
// Modificado: 27-nov-2025 - Parámetros de retención ajustados
// ==========================================
exports.cleanupInvalidFCMTokens = onSchedule({
  schedule: "every 24 hours",
  timeZone: "UTC",
  timeoutSeconds: 540,
  memory: "512MiB",
}, async (context) => {
  logger.info("Limpieza: Iniciando proceso.", {structuredData: true});

  const now = admin.firestore.Timestamp.now();

  // Parámetros de retención configurables
  const RETENTION_DAYS_LAST_LOGIN = 15;
  const RETENTION_DAYS_TOKENS = 30;

  const cutoffLastLogin = admin.firestore.Timestamp.fromMillis(now.toMillis() - (RETENTION_DAYS_LAST_LOGIN * 24 * 60 * 60 * 1000));
  const cutoffTokens = admin.firestore.Timestamp.fromMillis(now.toMillis() - (RETENTION_DAYS_TOKENS * 24 * 60 * 60 * 1000));

  let deletedUsers = 0;

  try {
    logger.info("Limpieza: Evaluando usuarios.", {structuredData: true});

    const usersSnapshot = await db.collection("users").get();
    let batch = db.batch();
    let batchCount = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      let shouldDelete = false;
      let deleteReason = "";

      const settingsRef = db.collection("users").doc(userId).collection("settings").doc("notifications");
      let settingsDoc;

      try {
        settingsDoc = await settingsRef.get();
      } catch (e) {
        logger.error(`Limpieza: Error al obtener settings de ${userId}.`, {structuredData: true});
        continue;
      }

      // Condición 1: Sin settings
      if (!settingsDoc.exists) {
        shouldDelete = true;
        deleteReason = "sin settings";
      }

      // Condición 2: lastLogin > 15 días (modificado)
      if (!shouldDelete) {
        const userData = userDoc.data();
        const lastLogin = userData?.lastLogin;

        if (!lastLogin || (lastLogin instanceof admin.firestore.Timestamp && lastLogin.toMillis() < cutoffLastLogin.toMillis())) {
          shouldDelete = true;
          deleteReason = `inactivo +${RETENTION_DAYS_LAST_LOGIN} días (lastLogin)`;
        }
      }

      // Condición 3: Todos los tokens son > 30 días o sin tokens
      if (!shouldDelete) {
        const tokensSnapshot = await db.collection("users").doc(userId).collection("fcmTokens").get();

        if (tokensSnapshot.empty) {
          shouldDelete = true;
          deleteReason = "sin tokens";
        } else {
          const allTokensOld = tokensSnapshot.docs.every((tokenDoc) => {
            const tokenData = tokenDoc.data();
            const createdAt = tokenData.createdAt;
            return createdAt instanceof admin.firestore.Timestamp && createdAt.toMillis() < cutoffTokens.toMillis();
          });

          if (allTokensOld) {
            shouldDelete = true;
            deleteReason = `todos tokens +${RETENTION_DAYS_TOKENS} días`;
          }
        }
      }

      // ELIMINAR USUARIO COMPLETO
      if (shouldDelete) {
        logger.info(`Limpieza: Eliminando usuario ${userId} (${deleteReason}).`, {structuredData: true});

        // Eliminar subcolecciones
        const tokensSnapshot = await db.collection("users").doc(userId).collection("fcmTokens").get();
        tokensSnapshot.docs.forEach((tokenDoc) => {
          batch.delete(tokenDoc.ref);
          batchCount++;
        });

        if (settingsDoc && settingsDoc.exists) {
          batch.delete(settingsRef);
          batchCount++;
        }

        // Eliminar documento principal
        batch.delete(userDoc.ref);
        batchCount++;
        deletedUsers++;

        if (batchCount >= 450) {
          await batch.commit();
          logger.info(`Limpieza: Batch commit (${deletedUsers} usuarios hasta ahora).`, {structuredData: true});
          batch = db.batch();
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    logger.info(`Limpieza: Completado. ${deletedUsers} usuarios eliminados completamente.`, {structuredData: true});
  } catch (error) {
    logger.error("Limpieza: Error general:", error, {structuredData: true});
  }

  return null;
});

// ── Prayer Wall ──────────────────────────────────────────────────────────────
const {onPrayerSubmitted} = require("./triggers/on_prayer_submitted");
exports.onPrayerSubmitted = onPrayerSubmitted;
