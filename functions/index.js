const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');
const { setGlobalOptions } = require('firebase-functions/v2');
const crypto = require('node:crypto');
const Razorpay = require('razorpay');
const { settlePayment } = require('./payments');
const { rollNumber, feeStatus, verifySignature, moveOccupants } = require('./domain');
initializeApp();
setGlobalOptions({ region: 'asia-south1', maxInstances: 10 });
const db = getFirestore(), auth = getAuth();
const keyId = defineSecret('RAZORPAY_KEY_ID');
const keySecret = defineSecret('RAZORPAY_KEY_SECRET');
const webhookSecret = defineSecret('RAZORPAY_WEBHOOK_SECRET');
const now = () => FieldValue.serverTimestamp();
const fail = (code, message) => { throw new HttpsError(code, message); };
function text(value, label, max = 200) {
  if (typeof value !== 'string' || !value.trim() || value.trim().length > max) fail('invalid-argument', `${label} is required (maximum ${max} characters).`);
  return value.trim();
}
function id(value) {
  const result = text(value, 'ID', 128);
  if (!/^[a-zA-Z0-9_-]+$/.test(result)) fail('invalid-argument', 'Invalid ID.');
  return result;
}
function money(value, label, allowZero = false) {
  if (!Number.isSafeInteger(value) || value < (allowZero ? 0 : 100) || value > 100000000) fail('invalid-argument', `${label} must be integer paise, up to ₹10 lakh.`);
  return value;
}
async function actor(request, role, ready = true) {
  if (!request.auth) fail('unauthenticated', 'Sign in first.');
  const profile = await db.doc(`users/${request.auth.uid}`).get();
  if (!profile.exists || profile.data().role !== role || request.auth.token.role !== role) fail('permission-denied', 'Access denied.');
  if (ready && profile.data().mustChangePassword) fail('failed-precondition', 'Change your initial password first.');
  return request.auth.uid;
}

// Resumable provisioning: reserve roll/room first, then create Auth with a deterministic UID.
// A failed network call is retried using the same roll. The stored request is authoritative.
exports.allotStudent = onCall(async request => {
  const adminUid = await actor(request, 'admin');
  const d = request.data || {};
  let roll;
  try { roll = rollNumber(d.rollNo); } catch (e) { fail('invalid-argument', e.message); }
  const uid = `stu_${crypto.createHash('sha256').update(roll).digest('hex').slice(0, 40)}`;
  const profile = { rollNo: roll, name: text(d.name, 'Name'), fatherName: text(d.fatherName, "Father's name"),
    contact: text(d.contact, 'Contact', 10), fatherContact: text(d.fatherContact, "Father's contact", 10),
    branch: text(d.branch, 'Branch'), year: Number(d.year), caste: text(d.caste, 'Caste'), address: text(d.address, 'Address', 1000),
    roomId: id(d.roomId), feeTotal: money(d.feeTotal, 'Total fee'), manualPaid: money(d.manualPaid, 'Amount already paid', true),
    onlinePaid: 0, email: `${roll}@hms.app`, authUid: uid };
  if (!/^[6-9][0-9]{9}$/.test(profile.contact) || !/^[6-9][0-9]{9}$/.test(profile.fatherContact)) fail('invalid-argument', 'Contacts must be valid 10-digit Indian mobile numbers.');
  if (![1, 2, 3, 4].includes(profile.year) || profile.manualPaid > profile.feeTotal) fail('invalid-argument', 'Check year and fee amounts.');
  profile.feeStatus = feeStatus(profile.feeTotal, profile.manualPaid);
  const userRef = db.doc(`users/${uid}`), studentRef = db.doc(`students/${uid}`), rollRef = db.doc(`rollNumbers/${roll}`);
  const stored = await db.runTransaction(async tx => {
    const existing = await tx.get(rollRef);
    if (existing.exists) {
      if (existing.data().state === 'ready') fail('already-exists', 'This roll number is already allotted.');
      const previous = await tx.get(studentRef);
      if (!previous.exists) fail('failed-precondition', 'Provisioning data is missing. Contact support.');
      return previous.data();
    }
    const roomRef = db.doc(`rooms/${profile.roomId}`), room = await tx.get(roomRef);
    if (!room.exists) fail('not-found', 'Room does not exist.');
    let moved;
    try { moved = moveOccupants([], room.data().occupantIds, uid, room.data().capacity); } catch (e) { fail('resource-exhausted', e.message); }
    const saved = { ...profile, block: room.data().block, roomNumber: room.data().number, createdAt: now() };
    tx.create(rollRef, { uid, state: 'pending', createdBy: adminUid, createdAt: now() });
    tx.create(userRef, { role: 'student', name: profile.name, rollNo: roll, mustChangePassword: true, provisioning: true });
    tx.create(studentRef, saved);
    tx.update(roomRef, { occupantIds: moved.next, occupied: moved.next.length });
    return saved;
  });
  let account;
  try { account = await auth.getUser(uid); } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    try { account = await auth.createUser({ uid, email: stored.email, password: stored.contact, displayName: stored.name, disabled: true }); }
    catch (creationError) {
      if (creationError.code !== 'auth/uid-already-exists') throw creationError;
      account = await auth.getUser(uid);
    }
  }
  await auth.setCustomUserClaims(uid, { ...account.customClaims, role: 'student' });
  await auth.updateUser(uid, { disabled: false });
  const batch = db.batch();
  batch.update(rollRef, { state: 'ready' });
  batch.update(userRef, { provisioning: false });
  await batch.commit();
  return { uid, rollNo: roll };
});

exports.changePassword = onCall(async request => {
  const uid = await actor(request, 'student', false);
  if (Date.now() / 1000 - request.auth.token.auth_time > 300) fail('unauthenticated', 'Sign in again before changing your password.');
  const password = request.data?.password;
  const student = await db.doc(`students/${uid}`).get();
  if (typeof password !== 'string' || password.length < 10 || password.length > 128 || !/[A-Za-z]/.test(password) || !/[0-9]/.test(password) || password === student.data()?.contact) fail('invalid-argument', 'Use 10–128 characters with letters and digits, different from your contact number.');
  await auth.updateUser(uid, { password });
  await db.doc(`users/${uid}`).update({ mustChangePassword: false });
  await auth.revokeRefreshTokens(uid);
  return { changed: true };
});

exports.saveRoom = onCall(async request => {
  await actor(request, 'admin');
  const block = text(request.data.block, 'Block', 60), number = text(request.data.number, 'Room number', 20);
  const capacity = Number(request.data.capacity);
  if (!Number.isInteger(capacity) || capacity < 1 || capacity > 20) fail('invalid-argument', 'Capacity must be 1–20.');
  const roomId = crypto.createHash('sha256').update(`${block.toLowerCase()}|${number.toLowerCase()}`).digest('hex').slice(0, 32);
  await db.runTransaction(async tx => {
    const ref = db.doc(`rooms/${roomId}`), snapshot = await tx.get(ref);
    const occupantIds = snapshot.data()?.occupantIds || [];
    if (occupantIds.length > capacity) fail('failed-precondition', 'Capacity cannot be below occupancy.');
    tx.set(ref, { block, number, capacity, occupantIds, occupied: occupantIds.length });
  });
  return { roomId };
});

exports.moveStudent = onCall(async request => {
  await actor(request, 'admin');
  const uid = id(request.data.uid), roomId = request.data.roomId ? id(request.data.roomId) : null;
  await db.runTransaction(async tx => {
    const studentRef = db.doc(`students/${uid}`), s = await tx.get(studentRef);
    if (!s.exists) fail('not-found', 'Student not found.');
    const oldRef = s.data().roomId ? db.doc(`rooms/${s.data().roomId}`) : null;
    const nextRef = roomId ? db.doc(`rooms/${roomId}`) : null;
    const old = oldRef ? await tx.get(oldRef) : null, next = nextRef ? await tx.get(nextRef) : null;
    if (nextRef && !next.exists) fail('not-found', 'Room not found.');
    if (oldRef?.path === nextRef?.path) return;
    let nextIds = [];
    if (nextRef) {
      try { nextIds = moveOccupants([], next.data().occupantIds, uid, next.data().capacity).next; }
      catch (e) { fail('resource-exhausted', e.message); }
    }
    if (old?.exists) {
      const ids = old.data().occupantIds.filter(v => v !== uid);
      tx.update(oldRef, { occupantIds: ids, occupied: ids.length });
    }
    if (nextRef) tx.update(nextRef, { occupantIds: nextIds, occupied: nextIds.length });
    tx.update(studentRef, { roomId, block: next?.data()?.block || '', roomNumber: next?.data()?.number || '' });
  });
  return { saved: true };
});

exports.updateFee = onCall(async request => {
  const adminUid = await actor(request, 'admin'), uid = id(request.data.uid);
  const feeTotal = money(request.data.feeTotal, 'Total fee'), manualPaid = money(request.data.manualPaid, 'Manual payment', true);
  await db.runTransaction(async tx => {
    const ref = db.doc(`students/${uid}`), student = await tx.get(ref);
    if (!student.exists) fail('not-found', 'Student not found.');
    const paid = manualPaid + student.data().onlinePaid;
    if (paid > feeTotal) fail('invalid-argument', 'Total fee cannot be below recorded payments.');
    tx.update(ref, { feeTotal, manualPaid, feeStatus: feeStatus(feeTotal, paid) });
    tx.create(db.collection('feeAdjustments').doc(), { uid, feeTotal, manualPaid, by: adminUid, createdAt: now() });
  });
  return { saved: true };
});

exports.registerDevice = onCall(async request => {
  if (!request.auth) fail('unauthenticated', 'Sign in first.');
  const user = await db.doc(`users/${request.auth.uid}`).get();
  const role = user.data()?.role;
  if (!['admin', 'student'].includes(role) || request.auth.token.role !== role) fail('permission-denied', 'Access denied.');
  const token = text(request.data.token, 'Token', 4096), hash = crypto.createHash('sha256').update(token).digest('hex');
  const ref = db.doc(`devices/${hash}`);
  if (request.data.remove === true) {
    const device = await ref.get();
    if (device.data()?.uid !== request.auth.uid) return { removed: true };
    await getMessaging().unsubscribeFromTopic(token, 'students');
    await ref.delete();
  } else {
    // Server-side topic subscription supports web as well as Android/iOS.
    if (role === 'student') await getMessaging().subscribeToTopic(token, 'students');
    else await getMessaging().unsubscribeFromTopic(token, 'students');
    await ref.set({ uid: request.auth.uid, role, token, updatedAt: now() });
  }
  return { saved: true };
});

exports.complaintNotification = onDocumentCreated({ document: 'complaints/{complaintId}', retry: true }, async event => {
  const complaint = event.data.data();
  const devices = await db.collection('devices').where('role', '==', 'admin').get();
  const student = await db.doc(`students/${complaint.studentId}`).get();
  const tokens = devices.docs.map(doc => doc.data().token);
  for (let i = 0; i < tokens.length; i += 500) {
    // Details are loaded after authentication; do not expose private complaint text on lock screens.
    await getMessaging().sendEachForMulticast({ tokens: tokens.slice(i, i + 500),
      notification: { title: 'New hostel complaint', body: `${student.data()?.name || 'Student'} (${student.data()?.rollNo || ''}) filed a complaint.` },
      data: { type: 'complaint', id: event.params.complaintId } });
  }
});
exports.noticeNotification = onDocumentCreated({ document: 'notices/{noticeId}', retry: true }, async event => {
  await getMessaging().send({ topic: 'students', notification: { title: 'Hostel notice', body: 'A new notice has been published.' }, data: { type: 'notice', id: event.params.noticeId } });
});

exports.createPaymentOrder = onCall({ secrets: [keyId, keySecret] }, async request => {
  const uid = await actor(request, 'student');
  const student = await db.doc(`students/${uid}`).get();
  const s = student.data();
  if (!s) fail('not-found', 'Student not found.');
  const amount = s.feeTotal - s.manualPaid - s.onlinePaid;
  if (amount < 100) fail('failed-precondition', 'No payable fee balance.');
  // Reuse a recent unpaid order so repeated button presses do not create parallel checkouts.
  const ref = db.doc(`paymentLocks/${uid}`), nonce = crypto.randomUUID();
  const cached = await db.runTransaction(async tx => {
    const lock = await tx.get(ref), data = lock.data();
    if (data?.orderId && data.amount === amount && data.expiresAt > Date.now()) return data;
    if (data?.creatingUntil > Date.now()) fail('aborted', 'An order is being created. Try again shortly.');
    tx.set(ref, { nonce, creatingUntil: Date.now() + 60000 });
    return null;
  });
  if (cached) return { orderId: cached.orderId, amount, currency: 'INR', key: keyId.value() };
  const razorpay = new Razorpay({ key_id: keyId.value(), key_secret: keySecret.value() });
  const receipt = `hms_${crypto.randomBytes(12).toString('hex')}`;
  const order = await razorpay.orders.create({ amount, currency: 'INR', receipt, notes: { uid } });
  const batch = db.batch();
  batch.create(db.doc(`paymentOrders/${order.id}`), { uid, amount, currency: 'INR', receipt, status: 'created', createdAt: now() });
  batch.set(ref, { orderId: order.id, amount, expiresAt: Date.now() + 15 * 60000, nonce });
  await batch.commit();
  return { orderId: order.id, amount, currency: 'INR', key: keyId.value() };
});

exports.razorpayWebhook = onRequest({ secrets: [webhookSecret] }, async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('POST required');
  if (!verifySignature(req.rawBody, req.get('x-razorpay-signature'), webhookSecret.value())) return res.status(401).send('Invalid signature');
  if (!['payment.captured', 'order.paid'].includes(req.body.event)) return res.status(200).send('Ignored');
  const payment = req.body.payload?.payment?.entity;
  if (!payment || payment.status !== 'captured' || !/^pay_[A-Za-z0-9]+$/.test(payment.id || '') || !/^order_[A-Za-z0-9]+$/.test(payment.order_id || '')) return res.status(400).send('Invalid payment');
  try {
    await settlePayment(db, payment);
    return res.status(200).send('OK');
  } catch (e) { console.error('Webhook settlement failed', e.message); return res.status(500).send('Retry settlement'); }
});

