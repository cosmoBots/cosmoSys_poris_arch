export function initializeRuntimeCad() {
  const root = document.querySelector('[data-poris-runtime-cad]');
  if (!root || root.dataset.initialized) return;
  root.dataset.initialized = 'true';
  // Changing the displayed choice must also replace the actual CAD/binding.
  // A select alone only changes the form draft, leaving the old scene active.
  const selectorForm = root.querySelector('[data-runtime-cad-selector]');
  selectorForm?.querySelector('select[name="cad_binding_id"]')?.addEventListener('change', () => {
    selectorForm.requestSubmit();
  });
  const scene = root.querySelector('#arch-cad-controls');
  const status = root.querySelector('[data-runtime-cad-status]');
  const parking = document.querySelector('[data-poris-runtime-cad-parking]');
  const dock = () => {
    const slot = document.querySelector('[data-poris-runtime-view-slot]');
    if (slot && !root.hidden) {
      slot.appendChild(root);
      // Native viewer may have initialized while its parking host was hidden.
      window.dispatchEvent(new Event('resize'));
    }
  };
  let pending = JSON.parse(root.querySelector('[data-runtime-cad-initial]').textContent);
  const apply = () => {
    status.hidden = true;
    if (!pending) {status.textContent = root.dataset.idleLabel; return;}
    if (pending.status === 'rejected') {status.textContent = pending.reason; status.hidden = false; pending = null; return;}
    if (scene.dataset.ready !== 'true') {status.textContent = root.dataset.waitingLabel; return;}
    const detail = {values: pending.values, result: {status:'rejected', reason:'CAD viewer unavailable'}};
    pending = null;
    scene.dispatchEvent(new CustomEvent('architecture:set-values', {detail}));
    status.textContent = detail.result.status === 'applied' ? root.dataset.appliedLabel : detail.result.reason;
    status.hidden = detail.result.status === 'applied';
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
    // Park before the tab loader replaces its DOM. Preserve the renderer and
    // confirmed pose across tabs, rather than orphaning a live WebGL canvas.
    if (parking) parking.appendChild(root);
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
  document.addEventListener('poris:tab-ready', dock);
  window.addEventListener('pagehide', () => {
    observer.disconnect();
    document.removeEventListener('poris:runtime-confirmed', receive);
    document.removeEventListener('poris:tab-selected', selectTab);
    document.removeEventListener('poris:tab-ready', dock);
  }, {once:true});
  apply();
  dock();
}
