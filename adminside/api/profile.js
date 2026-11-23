const { initFirebase, initServiceSupabase } = require('./_lib/init');
const { createProfileHandler } = require('./_lib/profile-handler');
module.exports = createProfileHandler({ initFirebase, initServiceSupabase });
