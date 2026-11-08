export function initializeSimulation(createPanel) {
  const initialize = () => {
    const root = document.getElementById('poris-arch-simulation');
    if (!root || root.dataset.initialized) return;
    root.dataset.initialized = 'true';
    const scene = root.querySelector('#arch-cad-controls');
    const status = document.querySelector('[data-simulation-status]');
    let pending = null;
    const send = (batch, command = false) => {
      const prefix = command ? 'Comando ejecutado. ' : '';
      if (scene.dataset.ready !== 'true') { pending = {batch, command}; status.textContent = `${prefix}Configuración confirmada; esperando al visor CAD…`; return; }
      const detail = {values: batch.values, result: {status: 'rejected', reason: 'CAD viewer not ready'}};
      scene.dispatchEvent(new CustomEvent('architecture:set-values', {detail}));
      status.textContent = prefix + (detail.result.status === 'applied' ? 'Configuración confirmada reflejada en el CAD.' : `No aplicado: ${detail.result.reason}`);
    };
    const observer = new MutationObserver(() => {
      if (scene.dataset.ready === 'true') {
        observer.disconnect();
        status.textContent = 'Visor listo. Configure PORIS y pulse Commit.';
        if (pending) { const {batch, command} = pending; pending = null; send(batch, command); }
      }
    });
    if (scene.dataset.ready === 'true') status.textContent = 'Visor listo. Configure PORIS y pulse Commit.';
    else observer.observe(scene, {attributes: true, attributeFilter: ['data-ready']});
    window.addEventListener('pagehide', () => observer.disconnect(), {once: true});
    createPanel('', '#poris-arch-panel', {
      compact: true,
      modelXml: JSON.parse(document.getElementById('poris-arch-model').textContent),
      initialState: JSON.parse(document.getElementById('poris-arch-state').textContent),
      commitUrl: root.dataset.commitUrl, csrfToken: root.dataset.csrfToken,
      onCommit: result => {
        // As in the project runtime viewer, observe confirmed state, not
        // command-triggered execution batches or unsaved panel drafts.
        const batch = result.observations?.architecture?.find(entry => String(entry.binding_id) === root.dataset.bindingId);
        const command = result.operations?.some(operation => operation.type === 'invoke_command' && operation.accepted);
        const prefix = command ? 'Comando ejecutado. ' : '';
        pending = null;
        if (!batch) { status.textContent = `${prefix}Configuración confirmada sin cambios CAD.`; return; }
        if (batch.status === 'rejected') { status.textContent = `${prefix}No aplicado: ${batch.reason}`; return; }
        send(batch, command);
      }
    });
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', initialize);
  else initialize();
}
