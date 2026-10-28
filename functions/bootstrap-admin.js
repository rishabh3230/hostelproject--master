// Run only from a trusted operator machine with Application Default Credentials.
// Usage: node bootstrap-admin.js <existing-auth-uid-or-email>
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
initializeApp();
async function main() {
  const identifier = process.argv[2];
  if (!identifier) throw new Error('Usage: node bootstrap-admin.js <existing-auth-uid-or-email>');
  const user = identifier.includes('@')
    ? await getAuth().getUserByEmail(identifier)
    : await getAuth().getUser(identifier);
  const uid = user.uid;
  await getAuth().setCustomUserClaims(uid, { ...user.customClaims, role: 'admin' });
  await getFirestore().doc(`users/${uid}`).set({ role: 'admin', name: user.displayName || 'Hostel administrator', mustChangePassword: false, provisioning: false });
  console.log('Administrator configured. Sign out and sign in to refresh claims.');
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
