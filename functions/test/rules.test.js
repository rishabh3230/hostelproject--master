const { test, before, after } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, serverTimestamp, collection, query, where, getDocs } = require('firebase/firestore');
const { ref, uploadBytes, getBytes } = require('firebase/storage');
const enabled = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
let env;
before(async () => {
  if (!enabled) return;
  env = await initializeTestEnvironment({ projectId: 'demo-hms', firestore: { rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8') },
    ...(process.env.FIREBASE_STORAGE_EMULATOR_HOST ? {storage:{rules:fs.readFileSync(path.join(__dirname, '../../storage.rules'),'utf8')}} : {}) });
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    for (const uid of ['alice','bob','first']) {
      await setDoc(doc(db, 'users', uid), {role:'student', mustChangePassword:uid === 'first', provisioning:false});
      await setDoc(doc(db, 'students', uid), {name:uid, feeTotal:50000});
    }
    await setDoc(doc(db, 'users', 'admin'), {role:'admin', mustChangePassword:false, provisioning:false});
    await setDoc(doc(db, 'rooms', 'r1'), {capacity:1, occupied:1, occupantIds:['alice']});
    await setDoc(doc(db, 'payments', 'p1'), {uid:'alice', amount:100});
  });
});
after(async () => { if (env) await env.cleanup(); });
test('students cannot self-promote, alter fees, or access another student', {skip:!enabled}, async () => {
  const db = env.authenticatedContext('alice', {role:'student'}).firestore();
  await assertFails(setDoc(doc(db,'admins','alice'), {role:'admin'}));
  await assertFails(updateDoc(doc(db,'users','alice'), {role:'admin'}));
  await assertFails(updateDoc(doc(db,'students','alice'), {feeTotal:0}));
  await assertFails(getDoc(doc(db,'students','bob')));
  await assertSucceeds(getDoc(doc(db,'students','alice')));
  await assertSucceeds(getDoc(doc(db,'rooms','r1')));
  await assertFails(getDocs(collection(db,'payments')));
  await assertSucceeds(getDocs(query(collection(db,'payments'), where('uid','==','alice'))));
});
test('first-login flag blocks data access and cannot be cleared by client', {skip:!enabled}, async () => {
  const db = env.authenticatedContext('first', {role:'student'}).firestore();
  await assertSucceeds(getDoc(doc(db,'users','first')));
  await assertFails(getDoc(doc(db,'students','first')));
  await assertFails(updateDoc(doc(db,'users','first'), {mustChangePassword:false}));
});
test('complaint creation validates ownership, state, fields, and attachment path', {skip:!enabled}, async () => {
  const db = env.authenticatedContext('alice', {role:'student'}).firestore();
  const complaint = {studentId:'alice', title:'Water', description:'Tap is broken', attachmentPath:'', status:'open', remark:'', createdAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(db,'complaints','c1'), complaint));
  await assertFails(setDoc(doc(db,'complaints','c2'), {...complaint, studentId:'bob'}));
  await assertFails(setDoc(doc(db,'complaints','c3'), {...complaint, status:'resolved'}));
  await assertFails(setDoc(doc(db,'complaints','c4'), {...complaint, attachmentPath:'complaints/bob/c4/attachment'}));
  await assertFails(updateDoc(doc(db,'complaints','c1'), {status:'resolved'}));
});
test('admin can resolve complaints but accounting mutations remain server-only', {skip:!enabled}, async () => {
  const db = env.authenticatedContext('admin', {role:'admin'}).firestore();
  await assertSucceeds(getDocs(collection(db,'students')));
  await assertSucceeds(updateDoc(doc(db,'complaints','c1'), {status:'resolved', remark:'Fixed', resolvedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db,'rooms','r1'), {occupied:0}));
  await assertFails(setDoc(doc(db,'payments','fake'), {uid:'alice',amount:100000}));
});
test('attachment rules enforce ownership, file type, first-login restriction, and admin notice uploads', {skip:!enabled || !process.env.FIREBASE_STORAGE_EMULATOR_HOST}, async () => {
  const alice = env.authenticatedContext('alice',{role:'student'}).storage();
  const bob = env.authenticatedContext('bob',{role:'student'}).storage();
  const first = env.authenticatedContext('first',{role:'student'}).storage();
  const adminStorage = env.authenticatedContext('admin',{role:'admin'}).storage();
  const bytes = new TextEncoder().encode('test attachment');
  const attachment = 'complaints/alice/storageTest/attachment';
  await assertSucceeds(uploadBytes(ref(alice,attachment),bytes,{contentType:'text/plain'}));
  await assertSucceeds(getBytes(ref(alice,attachment)));
  await assertFails(getBytes(ref(bob,attachment)));
  await assertFails(uploadBytes(ref(alice,'complaints/bob/invalid/attachment'),bytes,{contentType:'text/plain'}));
  await assertFails(uploadBytes(ref(alice,'complaints/alice/executable/attachment'),bytes,{contentType:'application/octet-stream'}));
  await assertFails(uploadBytes(ref(first,'complaints/first/new/attachment'),bytes,{contentType:'text/plain'}));
  await assertFails(uploadBytes(ref(alice,'notices/new/attachment'),bytes,{contentType:'text/plain'}));
  await assertSucceeds(uploadBytes(ref(adminStorage,'notices/adminNotice/attachment'),bytes,{contentType:'text/plain'}));
  await assertSucceeds(getBytes(ref(alice,'notices/adminNotice/attachment')));
});
test('feedback preserves student ownership and validates ratings', {skip:!enabled}, async () => {
  const db = env.authenticatedContext('alice',{role:'student'}).firestore();
  const feedback = {studentId:'alice',category:'Food',rating:4,message:'Good food',createdAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(db,'feedback','valid'),feedback));
  await assertFails(setDoc(doc(db,'feedback','spoofed'),{...feedback,studentId:'bob'}));
  await assertFails(setDoc(doc(db,'feedback','invalidRating'),{...feedback,rating:6}));
});
test('only admins create empty rooms and edit capacity without changing occupancy', {skip:!enabled}, async () => {
  const adminDb = env.authenticatedContext('admin',{role:'admin'}).firestore();
  const studentDb = env.authenticatedContext('alice',{role:'student'}).firestore();
  const room = {block:'Hostel 1',number:'301',capacity:3,occupied:0,occupantIds:[]};
  await assertFails(setDoc(doc(studentDb,'rooms','studentRoom'),room));
  await assertSucceeds(setDoc(doc(adminDb,'rooms','newRoom'),room));
  await assertSucceeds(updateDoc(doc(adminDb,'rooms','newRoom'),{capacity:4}));
  await assertFails(updateDoc(doc(adminDb,'rooms','newRoom'),{capacity:21}));
  await assertFails(updateDoc(doc(adminDb,'rooms','newRoom'),{occupantIds:['alice'],occupied:1}));
  await assertFails(setDoc(doc(adminDb,'rooms','preoccupied'),{...room,occupantIds:['alice'],occupied:1}));
  await assertFails(updateDoc(doc(adminDb,'rooms','r1'),{capacity:0}));
  await assertSucceeds(updateDoc(doc(adminDb,'rooms','r1'),{capacity:2}));
});
