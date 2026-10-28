const { test } = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const { rollNumber, feeStatus, verifySignature, moveOccupants } = require('../domain');
test('roll aliases normalize case and exclude email/path injection', () => {
  assert.equal(rollNumber('  CS_001  '), 'cs_001');
  for (const roll of ['x@y.com', '../admin', '', 'a', 'a b']) assert.throws(() => rollNumber(roll));
});
test('fee state respects partial payments and overpayment credits', () => {
  assert.equal(feeStatus(50000, 0), 'unpaid');
  assert.equal(feeStatus(50000, 20000), 'partial');
  assert.equal(feeStatus(50000, 50000), 'paid');
  assert.equal(feeStatus(50000, 60000), 'paid');
});
test('webhook authenticates exact raw bytes and rejects malformed signatures', () => {
  const raw = Buffer.from('{"id": 1}'), secret = 'test-only-secret';
  const signature = crypto.createHmac('sha256', secret).update(raw).digest('hex');
  assert.equal(verifySignature(raw, signature, secret), true);
  assert.equal(verifySignature(Buffer.from('{"id":1}'), signature, secret), false);
  assert.equal(verifySignature(raw, signature, 'wrong'), false);
  assert.equal(verifySignature(raw, 'xx', secret), false);
  assert.equal(verifySignature(raw, undefined, secret), false);
});
test('room move rejects full rooms, removes old occupancy, and is idempotent', () => {
  assert.throws(() => moveOccupants(['a'], ['b','c'], 'a', 2), /full/);
  assert.deepEqual(moveOccupants(['a','b'], ['c'], 'a', 2), {old: ['b'], next: ['c','a']});
  assert.deepEqual(moveOccupants(['a'], ['a'], 'a', 1, true), {old: ['a'], next: ['a']});
});
