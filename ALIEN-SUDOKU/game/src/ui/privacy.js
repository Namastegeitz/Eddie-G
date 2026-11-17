/* The privacy policy, readable inside the app (Google Play requires that). */
import { h } from './dom.js';
import { openModal } from './modal.js';
import { PUBLISHER } from '../data/publisher.js';
import policySource from '../data/privacy-policy.md?raw';

/** The policy with the publisher's details filled in (also used by tools/export-privacy.mjs). */
export function privacyPolicyText(p = PUBLISHER) {
  const contact = [p.supportEmail && `Email: ${p.supportEmail}`, p.website && `Website: ${p.website}`].filter(Boolean).join('  \n')
    || 'Use the contact details on the game\'s store page.';
  return policySource.replace(/\{\{DEVELOPER\}\}/g, p.name || 'the developer').replace(/\{\{CONTACT\}\}/g, contact);
}

/** Tiny Markdown subset: headings, lists, bold, italics, paragraphs, bare links. */
function render(md) {
  const esc = (s) => s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const inline = (s) => esc(s)
    .replace(/\*\*(.+?)\*\*/g, '<b>$1</b>')
    .replace(/\*(.+?)\*/g, '<i>$1</i>')
    .replace(/(https?:\/\/[^\s<]+)/g, '<a href="$1" target="_blank" rel="noopener">$1</a>')
    .replace(/ {2}\n/g, '<br>');
  return md.trim().split(/\n{2,}/).map((block) => {
    if (block.startsWith('# ')) return '';
    if (block.startsWith('## ')) return `<h3>${inline(block.slice(3))}</h3>`;
    if (/^- /m.test(block) && block.split('\n').every((l) => l.startsWith('- '))) {
      return `<ul>${block.split('\n').map((l) => `<li>${inline(l.slice(2))}</li>`).join('')}</ul>`;
    }
    return `<p>${inline(block)}</p>`;
  }).join('');
}

export function openPrivacyPolicy() {
  openModal({
    eyebrow: 'Privacy',
    title: 'Privacy policy',
    className: 'policy-modal',
    body: [
      h('div', { class: 'policy-text', html: render(privacyPolicyText()) }),
      PUBLISHER.privacyPolicyUrl ? h('p', { class: 'modal-text' }, h('a', { href: PUBLISHER.privacyPolicyUrl, target: '_blank', rel: 'noopener' }, 'Read it online')) : null,
    ],
    actions: [{ label: 'Close', kind: 'primary', autofocus: true }],
  });
}
