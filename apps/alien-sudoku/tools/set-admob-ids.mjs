#!/usr/bin/env node
/* Writes your real AdMob APPLICATION ids into the native projects.
   (Ad UNIT ids for banner/interstitial/rewarded go in .env — see .env.example.)

   ADMOB_ANDROID_APP_ID=ca-app-pub-1234~5678 ADMOB_IOS_APP_ID=ca-app-pub-1234~9012 node tools/set-admob-ids.mjs

   Without env vars it prints the ids currently in the projects. */
import { readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const strings = join(root, 'android/app/src/main/res/values/strings.xml');
const plist = join(root, 'ios/App/App/Info.plist');
const valid = (id) => /^ca-app-pub-\d+~\d+$/.test(id);

const { ADMOB_ANDROID_APP_ID: android, ADMOB_IOS_APP_ID: ios } = process.env;

function swap(file, re, value, label) {
  const src = readFileSync(file, 'utf8');
  const m = src.match(re);
  if (!m) throw new Error(`${label}: pattern not found in ${file}`);
  if (value == null) { console.log(`${label}: ${m[2]}`); return; }
  if (!valid(value)) throw new Error(`${label}: "${value}" is not an AdMob app id (ca-app-pub-XXXXXXXX~YYYYYYYY)`);
  writeFileSync(file, src.replace(re, `$1${value}$3`));
  console.log(`${label}: set to ${value}`);
}

swap(strings, /(<string name="admob_app_id">)([^<]*)(<\/string>)/, android, 'Android app id');
swap(plist, /(<key>GADApplicationIdentifier<\/key>\s*<string>)([^<]*)(<\/string>)/, ios, 'iOS app id');
