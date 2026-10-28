const crypto = require('node:crypto');
function rollNumber(value) {
  const roll = String(value || '').trim().toLowerCase();
  if (!/^[a-z0-9][a-z0-9_-]{1,39}$/.test(roll)) throw new Error('Roll number: 2–40 letters, digits, underscores or hyphens.');
  return roll;
}
function feeStatus(total, paid) { return paid >= total ? 'paid' : paid > 0 ? 'partial' : 'unpaid'; }
function verifySignature(raw, signature, secret) {
  if (!/^[a-f0-9]{64}$/i.test(signature || '')) return false;
  const expected = crypto.createHmac('sha256', secret).update(raw).digest();
  return crypto.timingSafeEqual(expected, Buffer.from(signature, 'hex'));
}
function moveOccupants(oldIds, newIds, uid, capacity, sameRoom = false) {
  const next = [...new Set([...newIds, uid])];
  if (next.length > capacity) throw new Error('Room is full.');
  return { old: sameRoom ? next : oldIds.filter(id => id !== uid), next };
}
module.exports = { rollNumber, feeStatus, verifySignature, moveOccupants };
