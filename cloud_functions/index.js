/**
 * Cloud Functions for Bupra Chat App
 *
 * This function sends push notifications when a new notification document
 * is created in Firestore.
 *
 * Setup:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Login: firebase login
 * 3. Initialize: firebase init functions
 * 4. Deploy: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Triggered when a new notification document is created
 * Sends FCM notification to the recipient
 */
exports.sendNotification = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snap, context) => {
        const notification = snap.data();

        // Skip if already processed
        if (notification.processed) {
            return null;
        }

        const { recipientToken, title, body, chatId, senderId } = notification;

        // Validate required fields
        if (!recipientToken || !title || !body) {
            console.error('Missing required fields in notification');
            return null;
        }

        // Prepare FCM message
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: {
                chatId: chatId || '',
                senderId: senderId || '',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            token: recipientToken,
            android: {
                priority: 'high',
                notification: {
                    sound: 'default',
                    channelId: 'bupra_messages',
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                    },
                },
            },
        };

        try {
            // Send notification via FCM
            const response = await admin.messaging().send(message);
            console.log('Successfully sent notification:', response);

            // Mark notification as processed
            await snap.ref.update({
                processed: true,
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return null;
        } catch (error) {
            console.error('Error sending notification:', error);

            // Mark as processed even on error to avoid retries
            await snap.ref.update({
                processed: true,
                error: error.message,
            });

            return null;
        }
    });

