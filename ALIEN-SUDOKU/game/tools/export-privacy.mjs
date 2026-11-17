#!/usr/bin/env node
/* Writes the privacy policy, with the publisher's details from src/data/publisher.js filled in,
   to a Markdown file you can host publicly (the store listings need its URL).
   node tools/export-privacy.mjs [out=../store-launch/privacy-policy.md] */
import { readFileSync, writeFileSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PUBLISHER } from '../src/data/publisher.js';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = resolve(process.argv[2] || join(root, '..', 'store-launch', 'privacy-policy.md'));
const p = PUBLISHER;
const contact = [p.supportEmail && `Email: ${p.supportEmail}`, p.website && `Website: ${p.website}`].filter(Boolean).join('  \n')
  || 'Use the contact details on the game\'s store page.';
const text = readFileSync(join(root, 'src', 'data', 'privacy-policy.md'), 'utf8')
  .replace(/\{\{DEVELOPER\}\}/g, p.name || 'the developer').replace(/\{\{CONTACT\}\}/g, contact);
writeFileSync(out, text);
console.log(`wrote ${out}${p.supportEmail ? '' : ' (no support email yet: fill in src/data/publisher.js)'}`);
