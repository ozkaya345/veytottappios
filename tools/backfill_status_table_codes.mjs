/**
 * One-off backfill script to create/update `status_table_codes` mapping docs.
 *
 * Why:
 * - Customers cannot read `status_tables` before a link exists, so "Kod ile Aç"
 *   resolves code -> tableId using `status_table_codes`.
 * - Older tables that already exist need this mapping to be backfilled.
 *
 * REQUIREMENTS:
 * - Firebase Admin SDK credentials (service account) available to the script.
 *
 * Usage (PowerShell):
 *   cd tools
 *   npm i firebase-admin
 *   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
 *   node .\backfill_status_table_codes.mjs
 *   node .\backfill_status_table_codes.mjs --dry-run
 *
 * What it does:
 * - Scans `status_tables` in pages.
 * - For each doc with a `code`, ensures `status_table_codes/{CODE}` exists
 *   and points to the same `tableId`.
 * - If a mapping exists but points to a different `tableId`, logs a conflict
 *   and skips (does not overwrite).
 */

import process from 'node:process';
import admin from 'firebase-admin';

function hasFlag(name) {
  return process.argv.includes(`--${name}`);
}

const dryRun = hasFlag('dry-run');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const PAGE_SIZE = 500;

let lastDoc = null;
let scanned = 0;
let created = 0;
let skippedNoCode = 0;
let skippedNoOwner = 0;
let skippedConflicts = 0;
let updated = 0;

while (true) {
  let query = db
    .collection('status_tables')
    .orderBy(admin.firestore.FieldPath.documentId())
    .limit(PAGE_SIZE);
  if (lastDoc) query = query.startAfter(lastDoc);

  const snap = await query.get();
  if (snap.empty) break;

  const batch = db.batch();
  let batchWrites = 0;

  for (const doc of snap.docs) {
    scanned++;
    const data = doc.data() ?? {};

    const rawCode = typeof data.code === 'string' ? data.code.trim() : '';
    if (!rawCode) {
      skippedNoCode++;
      continue;
    }

    const code = rawCode.toUpperCase();
    const ownerId = typeof data.ownerId === 'string' ? data.ownerId.trim() : '';
    if (!ownerId) {
      skippedNoOwner++;
      continue;
    }

    const trashed = data.trashed === true;

    const mapRef = db.collection('status_table_codes').doc(code);
    const mapSnap = await mapRef.get();

    if (mapSnap.exists) {
      const existing = mapSnap.data() ?? {};
      const existingTableId = typeof existing.tableId === 'string' ? existing.tableId.trim() : '';
      if (existingTableId && existingTableId !== doc.id) {
        skippedConflicts++;
        console.warn(`CONFLICT: code ${code} points to ${existingTableId}, not ${doc.id}. Skipping.`);
        continue;
      }

      // Ensure fields are present/up-to-date.
      const patch = {
        tableId: doc.id,
        ownerId,
        trashed,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (!dryRun) {
        batch.set(mapRef, patch, { merge: true });
        batchWrites++;
      }
      updated++;
      continue;
    }

    const newDoc = {
      tableId: doc.id,
      ownerId,
      trashed,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (!dryRun) {
      batch.set(mapRef, newDoc, { merge: true });
      batchWrites++;
    }
    created++;
  }

  if (batchWrites > 0) {
    await batch.commit();
    console.log(
      `Committed batch: writes=${batchWrites} (scanned so far: ${scanned})`,
    );
  }

  lastDoc = snap.docs[snap.docs.length - 1];
}

console.log('Done.');
console.log({
  dryRun,
  scanned,
  created,
  updated,
  skippedNoCode,
  skippedNoOwner,
  skippedConflicts,
});
