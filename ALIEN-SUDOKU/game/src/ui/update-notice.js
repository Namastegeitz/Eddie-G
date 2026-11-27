/* "A new version is available" (remote switch min_version) and "Please update"
   (force_below_version). See platform/remote.js. The forced notice can't be closed. */
import { h } from './dom.js';
import { openModal } from './modal.js';
import { openStorePage, canOpenStorePage } from '../platform/review.js';

export function showUpdateNotice({ force, message }) {
  const update = { label: 'Update', kind: 'primary', icon: 'play', autofocus: true,
    onClick: () => { openStorePage(); return force ? true : undefined; } };
  openModal({
    title: force ? 'Please update' : 'New version available',
    body: [h('p', { class: 'modal-text' }, message)],
    actions: force ? (canOpenStorePage() ? [update] : []) : [{ label: 'Later', kind: 'ghost' }, ...(canOpenStorePage() ? [update] : [])],
    dismissible: !force,
    className: 'update-notice',
  });
}
