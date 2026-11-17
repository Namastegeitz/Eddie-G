/* "Report an ad": App Store guideline 2.5.18 asks apps with ads to let players
   report inappropriate or age-inappropriate ads. */
import { h } from './dom.js';
import { openModal } from './modal.js';
import { PUBLISHER } from '../data/publisher.js';

export function openReportAd() {
  const mail = PUBLISHER.supportEmail
    ? `mailto:${PUBLISHER.supportEmail}?subject=${encodeURIComponent('Alien Sudoku: inappropriate ad')}&body=${encodeURIComponent('What did the ad show, and when did you see it (date, time, which screen)?\n\n')}`
    : null;
  openModal({
    eyebrow: 'Ads',
    title: 'Report an ad',
    body: [
      h('p', { class: 'modal-text' }, 'Saw an ad that looks wrong for this game? Ads here are meant to suit all ages.'),
      h('p', { class: 'modal-text' }, 'Quickest: tap the small ⓘ or ✕ in the corner of the ad and choose to report or hide it. Google reviews those reports.'),
      mail
        ? h('p', { class: 'modal-text' }, 'You can also tell us directly: ', h('a', { href: mail }, PUBLISHER.supportEmail), '. Say what the ad showed and when you saw it.')
        : h('p', { class: 'modal-text' }, 'You can also tell us through the contact details on the game\'s store page. Say what the ad showed and when you saw it.'),
    ],
    actions: [{ label: 'Close', kind: 'primary', autofocus: true }],
  });
}
