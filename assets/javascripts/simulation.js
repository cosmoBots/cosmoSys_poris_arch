export function initializeSimulation(createPanel) {
  const initialize = () => {
    const root = document.getElementById('poris-arch-simulation');
    if (!root || root.dataset.initialized) return;
    root.dataset.initialized = 'true';
    const scene = root.querySelector('#arch-cad-controls');
    const status = document.querySelector('[data-simulation-status]');
    let pending = null;
    const send = batch => {
      if (scene.dataset.ready !== 'true') { pending = batch; status.textContent = 'Orden validada; esperando al visor CAD…'; return; }
      const detail = {values: batch.values, result: {status: 'rejected', reason: 'CAD viewer not ready'}};
      scene.dispatchEvent(new CustomEvent('architecture:set-values', {detail}));
      status.textContent = detail.result.status === 'applied' ? 'Valores aplicados al CAD de esta sesión.' : `No aplicado: ${detail.result.reason}`;
    };
    const observer = new MutationObserver(() => {
      if (scene.dataset.ready === 'true') {
        observer.disconnect();
        status.textContent = 'Visor listo. Configure PORIS y ejecute un comando.';
        if (pending) { const batch = pending; pending = null; send(batch); }
      }
    });
    if (scene.dataset.ready === 'true') status.textContent = 'Visor listo. Configure PORIS y ejecute un comando.';
    else observer.observe(scene, {attributes: true, attributeFilter: ['data-ready']});
    window.addEventListener('pagehide', () => observer.disconnect(), {once: true});
    createPanel('', '#poris-arch-panel', {
      compact: true,
      modelXml: JSON.parse(document.getElementById('poris-arch-model').textContent),
      initialState: JSON.parse(document.getElementById('poris-arch-state').textContent),
      commitUrl: root.dataset.commitUrl, csrfToken: root.dataset.csrfToken,
      onCommit: result => {
        const batch = result.executions?.architecture?.find(entry => String(entry.binding_id) === root.dataset.bindingId);
        if (!batch) { status.textContent = 'Configuración aceptada sin actuación CAD.'; return; }
        if (batch.status === 'rejected') { status.textContent = `No aplicado: ${batch.reason}`; return; }
        send(batch);
      }
    });
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', initialize);
  else initialize();
}
