const { FieldValue } = require('firebase-admin/firestore');
const { feeStatus } = require('./domain');
async function settlePayment(db, payment) {
  await db.runTransaction(async tx => {
    const orderRef = db.doc(`paymentOrders/${payment.order_id}`), paymentRef = db.doc(`payments/${payment.id}`);
    const order = await tx.get(orderRef), previous = await tx.get(paymentRef);
    if (previous.exists) return;
    if (!order.exists) throw new Error('Order not recorded yet');
    const o = order.data();
    if (payment.amount !== o.amount || payment.currency !== o.currency) throw new Error('Order amount/currency mismatch');
    const studentRef = db.doc(`students/${o.uid}`), student = await tx.get(studentRef);
    const lockRef = db.doc(`paymentLocks/${o.uid}`), lock = await tx.get(lockRef);
    if (!student.exists) throw new Error('Missing student');
    if (o.status === 'paid') throw new Error('Order already settled by another payment');
    const s = student.data(), onlinePaid = s.onlinePaid + payment.amount;
    tx.create(paymentRef, { uid: o.uid, orderId: payment.order_id, amount: payment.amount, currency: payment.currency,
      receipt: o.receipt, createdAt: FieldValue.serverTimestamp(), paidAt: new Date(payment.created_at * 1000), status: 'captured' });
    tx.update(orderRef, { status: 'paid', paymentId: payment.id });
    tx.update(studentRef, { onlinePaid, feeStatus: feeStatus(s.feeTotal, s.manualPaid + onlinePaid) });
    if (lock.data()?.orderId === payment.order_id) tx.delete(lockRef);
  });
}
module.exports = { settlePayment };
