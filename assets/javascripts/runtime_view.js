export function initializeRuntimeCad() {
  const root = document.querySelector('[data-poris-runtime-cad]');
  if (!root || root.dataset.initialized) return;
  root.dataset.initialized = 'true';
  const scene = root.querySelector('#arch-cad-controls');
  const status = root.querySelector('[data-runtime-cad-status]');
  let pending = JSON.parse(root.querySelector('[data-runtime-cad-initial]').textContent);
  const apply = () => {
    if (!pending) {status.textContent = root.dataset.idleLabel; return;}
    if (pending.status === 'rejected') {status.textContent = pending.reason; pending = null; return;}
    if (scene.dataset.ready !== 'true') {status.textContent = root.dataset.waitingLabel; return;}
    const detail = {values: pending.values, result: {status:'rejected', reason:'CAD viewer unavailable'}};
    pending = null;
    scene.dispatchEvent(new CustomEvent('architecture:set-values', {detail}));
    status.textContent = detail.result.status === 'applied' ? root.dataset.appliedLabel : detail.result.reason;
  };
  const observer = new MutationObserver(() => {if (scene.dataset.ready === 'true') apply();});
  observer.observe(scene, {attributes:true, attributeFilter:['data-ready']});
  const receive = event => {
    // Only server-derived observations are consumed, never panel drafts or
    // command execution batches. Unknown mappings hold their previous pose.
    pending = event.detail.observations?.architecture?.find(batch => String(batch.binding_id) === root.dataset.bindingId) || null;
    apply();
  };
  const selectTab = event => {
    root.hidden = !['configuration','automated_validation'].includes(event.detail.tab);
    const input = root.querySelector('input[name="tab"]');
    if (input) input.value = event.detail.tab;
  };
  document.querySelectorAll?.('[data-poris-tab-link]').forEach(link => {
    const url = new URL(link.href);
    url.searchParams.set('cad_binding_id', root.dataset.bindingId);
    link.href = url.toString();
  });
  document.addEventListener('poris:runtime-confirmed', receive);
  document.addEventListener('poris:tab-selected', selectTab);
  window.addEventListener('pagehide', () => {
    observer.disconnect();
    document.removeEventListener('poris:runtime-confirmed', receive);
    document.removeEventListener('poris:tab-selected', selectTab);
  }, {once:true});
  apply();
}
