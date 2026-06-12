const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

admin.initializeApp();

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://jbhlbukxankrtcwhqoll.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_KEY;

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

exports.syncUserOnSignUp = functions.auth.user().onCreate(async (user) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .upsert({
        id: user.uid,
        email: user.email,
        display_name: user.displayName || '',
        photo_url: user.photoURL || '',
        sign_up_date: new Date().toISOString(),
        last_login: new Date().toISOString(),
        is_active: true,
      }, { onConflict: 'id' });

    if (error) {
      console.error('Error syncing user to Supabase:', error);
      throw new Error(`Supabase sync failed: ${error.message}`);
    }

    console.log(`User ${user.uid} synced to Supabase`, data);
    return { success: true, userId: user.uid };
  } catch (error) {
    console.error('Error in syncUserOnSignUp:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

exports.updateUserLoginTime = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const uid = context.auth.uid;

  try {
    const { error } = await supabase
      .from('users')
      .update({
        last_login: new Date().toISOString(),
      })
      .eq('id', uid);

    if (error) {
      console.error('Error updating login time:', error);
      throw new Error(error.message);
    }

    return { success: true, message: 'Login time updated' };
  } catch (error) {
    console.error('Error in updateUserLoginTime:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
