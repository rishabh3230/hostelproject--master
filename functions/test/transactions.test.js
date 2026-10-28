const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const enabled = Boolean(process.env.FIRESTORE_EMULATOR_HOST && process.env.FIREBASE_AUTH_EMULATOR_HOST);
let functions, db, auth;
const admin = { uid:'functionAdmin', token:{role:'admin'} };
before(async () => {
  if (!enabled) return;
  process.env.GCLOUD_PROJECT = 'demo-hms';
  functions = require('../index');
  db = require('firebase-admin/firestore').getFirestore();
  auth = require('firebase-admin/auth').getAuth();
  await db.doc('users/functionAdmin').set({role:'admin', mustChangePassword:false});
});
after(async () => { if (enabled) await require('firebase-admin/app').deleteApp(require('firebase-admin/app').getApp()); });
test('concurrent allotments cannot overbook and creation never changes the admin identity', {skip:!enabled}, async () => {
  const {roomId} = await functions.saveRoom.run({auth:admin, data:{block:'TransactionTest',number:'101',capacity:1}});
  const base = {name:'Test student', fatherName:'Test father', contact:'9876543210', fatherContact:'9876543211', branch:'CS', year:1, caste:'General', address:'Test address', roomId, feeTotal:50000, manualPaid:0};
  const results = await Promise.allSettled(['tx001','tx002'].map(rollNo => functions.allotStudent.run({auth:admin, data:{...base,rollNo}})));
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  const loser = results.find(r => r.status === 'rejected');
  assert.equal(loser.reason.code, 'resource-exhausted');
  const winner = results.find(r => r.status === 'fulfilled').value;
  const room = (await db.doc(`rooms/${roomId}`).get()).data();
  assert.equal(room.occupied, 1);
  assert.deepEqual(room.occupantIds, [winner.uid]);
  const account = await auth.getUser(winner.uid);
  assert.equal(account.email, `${winner.rollNo}@hms.app`);
  assert.equal(account.customClaims.role, 'student');
  assert.equal((await db.doc(`users/${winner.uid}`).get()).data().mustChangePassword, true);
  assert.equal((await db.doc('users/functionAdmin').get()).data().role, 'admin');
  await assert.rejects(functions.allotStudent.run({auth:admin,data:{...base,rollNo:winner.rollNo}}), {code:'already-exists'});
  await assert.rejects(functions.moveStudent.run({auth:{uid:winner.uid,token:{role:'student'}},data:{uid:winner.uid,roomId:''}}), {code:'permission-denied'});
  const target = await functions.saveRoom.run({auth:admin,data:{block:'TransactionTest',number:'102',capacity:1}});
  await Promise.all([
    functions.moveStudent.run({auth:admin,data:{uid:winner.uid,roomId:target.roomId}}),
    functions.moveStudent.run({auth:admin,data:{uid:winner.uid,roomId:''}}),
  ]);
  const student = (await db.doc(`students/${winner.uid}`).get()).data();
  const rooms = await Promise.all([roomId,target.roomId].map(async id => ({id,...(await db.doc(`rooms/${id}`).get()).data()})));
  for (const r of rooms) { assert.equal(r.occupied,r.occupantIds.length); assert.equal(r.occupantIds.includes(winner.uid),student.roomId === r.id); }
});
test('duplicate payment events settle once and amount tampering cannot mark fees paid', {skip:!enabled}, async () => {
  const {settlePayment} = require('../payments');
  await db.doc('students/paymentTest').set({feeTotal:50000,manualPaid:10000,onlinePaid:0,feeStatus:'partial'});
  await db.doc('paymentOrders/order_test1').set({uid:'paymentTest',amount:40000,currency:'INR',receipt:'receipt-test',status:'created'});
  await db.doc('paymentLocks/paymentTest').set({orderId:'order_test1'});
  const payment = {id:'pay_test1',order_id:'order_test1',amount:40000,currency:'INR',created_at:1700000000};
  await assert.rejects(settlePayment(db,{...payment,amount:1}), /mismatch/);
  await assert.rejects(settlePayment(db,{...payment,currency:'USD'}), /mismatch/);
  await Promise.all([settlePayment(db,payment),settlePayment(db,payment)]);
  const student = (await db.doc('students/paymentTest').get()).data();
  assert.equal(student.onlinePaid,40000);
  assert.equal(student.feeStatus,'paid');
  assert.equal((await db.doc('payments/pay_test1').get()).data().receipt,'receipt-test');
  assert.equal((await db.doc('paymentLocks/paymentTest').get()).exists,false);
});
