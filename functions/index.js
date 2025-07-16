// functions/index.js

// Importa las librerías necesarias de Firebase Functions y Firebase Admin SDK.
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
const { logger } = require('firebase-functions');
const { setGlobalOptions } = require('firebase-functions/v2'); // Para configurar opciones globales

// Importa la librería Luxon para manejo avanzado de fechas y zonas horarias.
const { DateTime } = require('luxon');

// --- Configuración Global para Cloud Functions v2 ---
// Esto ayuda a establecer opciones comunes para todas las funciones, incluyendo la región.
setGlobalOptions({ region: 'us-central1' }); // Asegúrate de que esta sea tu región preferida

// --- Inicialización de Firebase Admin ---
// Este bloque se ejecuta una vez cuando la función se carga por primera vez.
logger.info('Cloud Function: Iniciando el proceso de inicialización de la función.', { structuredData: true });

try {
    // Inicializa el Admin SDK. Esto permite que tu función interactúe con tu proyecto de Firebase.
    // Si la función se despliega en Firebase, las credenciales se autoconfiguran.
    // Asegura que el Admin SDK solo se inicialice una vez.
    if (!admin.apps.length) {
        admin.initializeApp();
        logger.info('Cloud Function: Firebase Admin SDK inicializado.', { structuredData: true });
    } else {
        logger.info('Cloud Function: Firebase Admin SDK ya inicializado.', { structuredData: true });
    }
} catch (e) {
    logger.error('Cloud Function: Error durante la inicialización de Firebase Admin SDK:', e, { structuredData: true });
    throw e; // Relanzar el error para que Cloud Run lo detecte.
}

// Obtiene una referencia a la base de datos Firestore.
const db = admin.firestore();
logger.info('Cloud Function: Referencia a Firestore obtenida.', { structuredData: true });


// Define la Cloud Function principal para enviar notificaciones diarias.
// Se activará CADA HORA en UTC para optimizar costos en producción.
exports.sendDailyDevotionalNotification = onSchedule({
    schedule: '0 * * * *', // CAMBIO AQUÍ: Ejecutar CADA HORA (minuto 0, cualquier hora, cualquier día, cualquier mes, cualquier día de la semana)
    timeZone: 'UTC',       // IMPORTANTE: La función se ejecuta en UTC.
    // Opcional: Configurar límites de recursos para la función (ajustar según necesidad y presupuesto)
    // memory: '128MiB', // Puedes aumentar si la lógica de usuario es muy pesada
    // timeoutSeconds: 300, // 5 minutos, por si las consultas son lentas
}, async (context) => {
    logger.info('Cloud Function: sendDailyDevotionalNotification - Ejecución iniciada.', { structuredData: true });

    let devotionalTitle = 'Devocional Diario';
    let devotionalBody = '¡Es hora de tu devocional diario!\n¡Recuerda conectarte hoy, con la palabra de Dios!';
    // TODO: En un paso futuro, puedes obtener el devocional real de Firestore aquí.
    /*
    try {
        logger.info('Cloud Function: Intentando obtener devocional del día de Firestore.', { structuredData: true });
        const devotionalDoc = await db.collection('devotionals').doc('devocionalDelDia').get();
        if (devotionalDoc.exists) {
            const data = devotionalDoc.data();
            devotionalTitle = data.title || devotionalTitle;
            devotionalBody = data.body.substring(0, 100) + '...' || devotionalBody;
            logger.info('Cloud Function: Devocional obtenido exitosamente.', { structuredData: true });
        } else {
            logger.warn('Cloud Function: No se encontró el devocional del día en Firestore. Usando valores predeterminados.', { structuredData: true });
        }
    } catch (error) {
        logger.error('Cloud Function: Error al obtener el devocional del día:', error, { structuredData: true });
    }
    */

    const tokensToSend = [];

    // Obtener todos los usuarios
    logger.info('Cloud Function: Consultando la colección de usuarios en Firestore.', { structuredData: true });
    const usersRef = db.collection('users');
    const usersSnapshot = await usersRef.get();

    if (usersSnapshot.empty) {
        logger.info('Cloud Function: No se encontraron usuarios en la colección "users".', { structuredData: true });
        return null;
    }
    logger.info(`Cloud Function: Se encontraron ${usersSnapshot.size} usuarios.`, { structuredData: true });

    // Obtener la hora actual en UTC para la comparación
    const nowUtc = DateTime.now().setZone('UTC');
    logger.info(`Cloud Function: Hora actual UTC: ${nowUtc.toFormat('HH:mm')}.`, { structuredData: true });


    for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        logger.info(`Cloud Function: Procesando usuario: ${userId}.`, { structuredData: true });

        const settingsRef = db.collection('users').doc(userId).collection('settings').doc('notifications');
        let settingsDoc;
        try {
            settingsDoc = await settingsRef.get();
        } catch (e) {
            logger.error(`Cloud Function: Error al obtener configuración de notificaciones para usuario ${userId}:`, e, { structuredData: true });
            continue;
        }


        if (settingsDoc.exists) {
            const settingsData = settingsDoc.data();
            const notificationsEnabled = settingsData.notificationsEnabled;
            const notificationTime = settingsData.notificationTime; // "HH:MM"
            const userTimezone = settingsData.userTimezone; // Zona horaria del usuario (ej. "America/New_York")

            logger.info(`Cloud Function: Configuración para ${userId}: Habilitado: ${notificationsEnabled}, Hora: ${notificationTime}, Zona horaria: ${userTimezone}.`, { structuredData: true });


            // Si no hay zona horaria o notificaciones deshabilitadas, saltar este usuario
            if (!notificationsEnabled || !userTimezone) {
                logger.info(`Cloud Function: Usuario ${userId} no elegible (notificaciones deshabilitadas o zona horaria no definida).`, { structuredData: true });
                continue;
            }

            // Convertir la hora actual UTC a la zona horaria del usuario
            // y luego comparar con la hora de notificación preferida del usuario.
            try {
                // Verificar si la zona horaria es válida antes de usarla
                if (!DateTime.local().setZone(userTimezone).isValid) {
                    logger.warn(`Cloud Function: Zona horaria inválida para usuario ${userId}: ${userTimezone}. Saltando.`, { structuredData: true });
                    continue;
                }

                const userLocalTime = nowUtc.setZone(userTimezone);
                const [preferredHour, preferredMinute] = notificationTime.split(':').map(Number);

                // Verificar si la hora actual en la zona horaria del usuario
                // coincide con su hora de notificación preferida.
                // Damos un margen de 5 minutos para la ejecución del cron.
                const isTimeToSend = (
                    userLocalTime.hour === preferredHour &&
                    userLocalTime.minute >= preferredMinute &&
                    userLocalTime.minute < preferredMinute + 5
                );

                logger.info(`Cloud Function: Usuario ${userId} - Hora local calculada: ${userLocalTime.toFormat('HH:mm')}, Hora preferida: ${notificationTime}, ¿Es hora de enviar?: ${isTimeToSend}.`, { structuredData: true });


                if (isTimeToSend) {
                    logger.info(`Cloud Function: Usuario ${userId} es elegible. Recopilando tokens FCM.`, { structuredData: true });
                    const fcmTokensRef = db.collection('users').doc(userId).collection('fcmTokens');
                    const fcmTokensSnapshot = await fcmTokensRef.get();

                    if (!fcmTokensSnapshot.empty) {
                        fcmTokensSnapshot.docs.forEach(tokenDoc => {
                            const tokenData = tokenDoc.data();
                            if (tokenData.token) {
                                tokensToSend.push(tokenData.token);
                            }
                        });
                        logger.info(`Cloud Function: ${fcmTokensSnapshot.size} tokens encontrados para usuario ${userId}.`, { structuredData: true });
                    } else {
                        logger.warn(`Cloud Function: Usuario ${userId} no tiene tokens FCM registrados.`, { structuredData: true });
                    }
                }
            } catch (e) {
                logger.error(`Cloud Function: Error procesando lógica de zona horaria para usuario ${userId}: ${e.message}`, { structuredData: true });
            }
        } else {
            logger.info(`Cloud Function: Usuario ${userId} no tiene documento de configuración de notificaciones.`, { structuredData: true });
        }
    }

    if (tokensToSend.length === 0) {
        logger.info('Cloud Function: No hay tokens FCM válidos para enviar notificaciones en este momento.', { structuredData: true });
        return null;
    }

    // 2. Enviar la notificación a todos los tokens recolectados
    logger.info(`Cloud Function: Preparando para enviar notificación a ${tokensToSend.length} tokens.`, { structuredData: true });
    const message = {
        notification: {
            title: devotionalTitle,
            body: devotionalBody,
        },
        data: {
            devotionalId: 'daily',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        tokens: tokensToSend,
    };

    try {
        const response = await admin.messaging().sendEachForMulticast(message);
        logger.info(`Cloud Function: Notificaciones enviadas exitosamente a ${response.successCount} dispositivos. Fallaron ${response.failureCount}.`, { structuredData: true });

        if (response.failureCount > 0) {
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    const failedToken = tokensToSend[idx];
                    logger.error(`Cloud Function: Falló el envío al token ${failedToken}: ${resp.error?.code || resp.error?.message || 'Error desconocido'}.`, { structuredData: true });
                }
            });
        }
    } catch (error) {
        logger.error('Cloud Function: Error general al enviar notificaciones FCM:', error, { structuredData: true });
    }

    logger.info('Cloud Function: Ejecución de sendDailyDevotionalNotification finalizada.', { structuredData: true });
    return null;
});


/**
 * Función de Cloud Function programada para limpiar tokens FCM inválidos.
 * Se ejecutará cada 24 horas.
 *
 * Esta función:
 * 1. Recupera todos los tokens FCM almacenados en Firestore.
 * 2. Envía un mensaje de prueba (o un mensaje de datos silencioso) a estos tokens.
 * Esto provoca que FCM informe qué tokens son inválidos.
 * 3. Itera sobre la respuesta de FCM e identifica los tokens que fallaron.
 * 4. Elimina los tokens inválidos de la base de datos de Firestore.
 */
exports.cleanupInvalidFCMTokens = onSchedule({
    schedule: 'every 24 hours', // Ejecutar cada 24 horas para la limpieza
    timeZone: 'UTC',
    // memory: '128MiB', // Ajusta según la cantidad de tokens que esperes
    // timeoutSeconds: 300, // Ajusta según el tiempo que tarde en procesar
}, async (context) => {
    logger.info('Cloud Function: Iniciando la limpieza de tokens FCM inválidos.', { structuredData: true });

    const tokensToDelete = [];

    try {
        // 1. Recuperar todos los tokens FCM de la colección 'fcmTokens' de cada usuario
        // Asume que tus tokens están en 'users/{userId}/fcmTokens/{tokenId}'
        const usersSnapshot = await db.collection('users').get();

        const allTokens = [];
        for (const userDoc of usersSnapshot.docs) {
            const userId = userDoc.id;
            const fcmTokensSnapshot = await db.collection('users').doc(userId).collection('fcmTokens').get();
            fcmTokensSnapshot.docs.forEach(tokenDoc => {
                const tokenData = tokenDoc.data();
                if (tokenData.token) {
                    allTokens.push({
                        token: tokenData.token,
                        ref: tokenDoc.ref // Referencia al documento para facilitar la eliminación
                    });
                }
            });
        }

        if (allTokens.length === 0) {
            logger.info('Cloud Function: No se encontraron tokens FCM para limpiar.', { structuredData: true });
            return null;
        }

        logger.info(`Cloud Function: Se encontraron ${allTokens.length} tokens para verificar.`, { structuredData: true });

        // 2. Enviar un mensaje de prueba a los tokens para verificar su validez.
        // Se recomienda usar un mensaje de datos silencioso para no molestar al usuario.
        // FCM permite enviar hasta 500 tokens por solicitud.
        const tokensChunks = [];
        for (let i = 0; i < allTokens.length; i += 500) {
            tokensChunks.push(allTokens.slice(i, i + 500).map(t => t.token));
        }

        for (const chunk of tokensChunks) {
            const message = {
                data: {
                    type: 'cleanup_check',
                    timestamp: new Date().toISOString()
                },
                tokens: chunk,
            };

            try {
                const response = await admin.messaging().sendEachForMulticast(message);
                logger.info(`Cloud Function: Respuesta de FCM para un chunk: ${response.successCount} exitosos, ${response.failureCount} fallidos.`, { structuredData: true });

                // 3. Identificar tokens inválidos
                response.responses.forEach((resp, index) => {
                    if (!resp.success) {
                        // El token falló, es inválido o no registrado
                        const failedToken = chunk[index];
                        // Encontrar la referencia del documento original para eliminar
                        const tokenRef = allTokens.find(t => t.token === failedToken)?.ref;
                        if (tokenRef) {
                            tokensToDelete.push(tokenRef);
                        }
                        logger.warn(`Cloud Function: Token inválido detectado: ${failedToken} - Error: ${resp.error?.message}.`, { structuredData: true });
                    }
                });
            } catch (error) {
                logger.error('Cloud Function: Error al enviar mensajes a un chunk de tokens:', error, { structuredData: true });
            }
        }

        // 4. Eliminar los tokens inválidos de Firestore
        if (tokensToDelete.length > 0) {
            const batch = db.batch();
            tokensToDelete.forEach(tokenRef => {
                batch.delete(tokenRef);
            });
            await batch.commit();
            logger.info(`Cloud Function: Se eliminaron ${tokensToDelete.length} tokens inválidos de Firestore.`, { structuredData: true });
        } else {
            logger.info('Cloud Function: No se encontraron tokens inválidos para eliminar.', { structuredData: true });
        }

        logger.info('Cloud Function: Limpieza de tokens FCM completada.', { structuredData: true });

    } catch (error) {
        logger.error('Cloud Function: Error general en la función de limpieza de tokens:', error, { structuredData: true });
    }

    return null;
});
