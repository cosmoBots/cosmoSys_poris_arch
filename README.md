# cosmoSys PORIS Architecture

Version **0.1.0**, first development implementation. Optional integration:
Architecture and PORIS continue operating independently without this plugin.

## Model

- A binding connects a `poris_sys` with an `arch_node` in the **same project
  tree**. Forms resolve CSIDs only in that tree. Native endpoint IDs and foreign
  keys store the relationships; names are never identity.
- Each parameter link connects a descendant `poris_param` to a descendant
  `arch_dof`. The DoF still controls only its immediate structural parent.
  A parameter can drive several DoFs, and different parameters can target the
  same DoF in mutually exclusive PORIS modes. The binding/parameter/DoF triple
  is unique. If two active parameters target the same DoF, the whole batch is
  rejected rather than choosing a writer or depending on database order.
- Conversion is `CAD = m × x + h`. Numeric PORIS options supply their runtime
  data. Discrete options require an explicit JSON mapping of **value CSID** to
  numeric `x`, for example `{"POR-0012": 45}`; conversion follows the mapping.
- Default trigger: **command**. Commands belonging to the bound system and its
  subsystems act by default; an individual command can disable CAD actuation.
  Alternatively choose **commit**, including a commit carried by a command
  request. Each binding produces at most one batch per runtime request.

The server-side PORIS runtime reconciles the configuration before dispatch.
Parameters in its implicit `Unknown` mode are omitted, even if stale numeric
data accompanies the row: Unknown never means zero or a return to rest. If all
mapped parameters are Unknown, no batch is generated. An active parameter
without a selected value remains an error, not an implicit skip.

All links and active conversions are checked before producing a batch. Missing
translations, invisible endpoints, missing runtime rows, non-finite numbers or
out-of-range results reject the entire binding's batch: no silent clamping,
defaults or partial motion. A rejected PORIS operation suppresses execution.

## Evaluation

Open **PORIS ↔ CAD** in the project's menu; create the system/component binding,
then add parameter mappings and command policies. The binding page combines a
compact PORIS configuration panel in Redmine's right sidebar and the existing
architectural CAD viewer directly in the page body. The shared Architecture
viewer partial keeps the standalone viewer's visibility checks and controls;
there is no nested Redmine page or CAD iframe. PORIS loads its normal viewer
stylesheet. Its runtime commit endpoint returns prepared batches; only that
page's CAD controls apply them and acknowledge the result through the generic
`architecture:set-values` DOM event. Other users/tabs are not broadcast targets.
Manual CAD sliders remain available for inspection. A batch arriving before
the CAD viewer is ready waits locally until its controls are initialized.

The viewer's generic `architecture:set-values` batch API preserves exact
numbers independently of HTML slider step quantization. Pose is temporary;
neither original geometry nor item defaults are changed. `prepared` is not
reported as hardware execution. No MQTT, Godot, coupling formulas, motion
trajectories or physical equipment are involved in this first implementation.

## Installation and scope

Depends on cosmoSys >=0.2.8, Architecture >=0.1.3 and PORIS
>=0.2.4 (generic optional runtime execution adapter). Development Compose
loads this directory as `cosmosys_zzporis_arch` after both dependencies; registered
plugin ID is `cosmosys_poris_arch`. Apply its migration before starting Redmine.
Migration uses only Rails schema APIs, with issue FK width taken from the host
schema. Two up/down cycles pass in SQLite, MySQL and PostgreSQL labs, preserving
existing host items. SQLite additionally exercises conversions, discrete options,
root checks, triggers and atomic batch rejection. JavaScript tests verify exact
values, range checks, binding isolation, readiness and local acknowledgements. Installed in
3001 after a verified backup. Transactional Redmine checks pass for the real page,
command policy, dispatch and anonymous write protection. A real Chrome/WebGL test
with a temporary read-only user passes panel → runtime → command → CAD and
repeats without accumulating transforms. The transactional fixture covers both
elevation -30 / azimuth 45; browser checks respect the demo's current mappings.

Demo: <http://localhost:3001/projects/poris-tests/poris-arch/3>.
Select **Operation → Pointing**, enter values, then press **command**. Current
demo links use m=1 / h=0; only azimuth is mapped, so elevation remains unchanged
until its parameter mapping is added. HOME/PARK/TECH translations
are deliberately unset: configure them explicitly rather than assuming poses.
Do not use positive elevation with the identity conversion: this CAD DoF ranges
from -90 to 0. Choose the appropriate calibration in the link when agreed.

Permissions: `view_poris_arch` to inspect; `manage_poris_arch` and `edit_issues`
on both endpoint projects to edit (administrators allowed). Each runtime action
also checks endpoint visibility and PORIS access. Configure these deliberately
before granting access to other users.

**Current limitation:** the new integration binding tables are not yet included
in project snapshots/ODS. Existing PORIS and architectural CAD items continue to
roundtrip, but their integration bindings must currently be recreated. Do not
promote this prototype as a release or add deploy pins yet.

## License

Licensed under the GNU General Public License, version 3. See [LICENSE](LICENSE).
