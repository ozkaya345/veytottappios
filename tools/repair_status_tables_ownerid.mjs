/**
 * One-off repair script for legacy `status_tables` documents that were created
 * without `ownerId` due to older app bugs.
 *
 * REQUIREMENTS:
 * - Firebase Admin SDK credentials (service account) available to the script.
 * - A target UID to assign as ownerId.
 *
 * Usage (PowerShell):
 *   cd tools
 *   npm i firebase-admin
 *   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
 *   node .\repair_status_tables_ownerid.mjs --uid <USER_UID>
 *
 * What it does:
 * - Finds documents in `status_tables` where `ownerId` is missing/null/empty.
 * - Sets `ownerId` to the given UID.
 * - Optionally sets `trashed=false` if missing.
 */

import process from 'node:process';
import admin from 'firebase-admin';

function getArg(name) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1) return null;
  return process.argv[idx + 1] ?? null;
}

const uid = getArg('uid');
if (!uid) {
  console.error('Missing required arg: --uid <USER_UID>');
  process.exit(1);
}

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Firestore has no direct "where field is missing" query.
// So we scan in pages and repair where needed.
const PAGE_SIZE = 500;

let lastDoc = null;
let repaired = 0;
let scanned = 0;

while (true) {
  let query = db.collection('status_tables').orderBy(admin.firestore.FieldPath.documentId()).limit(PAGE_SIZE);
  if (lastDoc) query = query.startAfter(lastDoc);

  const snap = await query.get();
  if (snap.empty) break;

  const batch = db.batch();
  let batchWrites = 0;

  for (const doc of snap.docs) {
    scanned++;
    const data = doc.data() ?? {};
    const ownerId = typeof data.ownerId === 'string' ? data.ownerId.trim() : '';

    if (!ownerId) {
      const patch = {
        ownerId: uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (data.trashed === undefined || data.trashed === null) {
        patch.trashed = false;
      }
      batch.set(doc.ref, patch, { merge: true });
      batchWrites++;
      repaired++;
    }
  }

  if (batchWrites > 0) {
    await batch.commit();
    console.log(`Committed batch: repaired ${batchWrites} docs (scanned so far: ${scanned})`);
  }

  lastDoc = snap.docs[snap.docs.length - 1];
}

console.log(`Done. Scanned: ${scanned}, repaired: ${repaired}`);
