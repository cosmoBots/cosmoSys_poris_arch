# cosmoSys PORIS Architecture

Version **0.1.0**. Optional integration: Architecture and PORIS work
independently without this plugin.

> **EXPERIMENTAL — opt-in:** This plugin is not part of the production core.
> Expect defects, incomplete features, performance limits and breaking changes.
> Do not install it if you require production-level stability and support.

## Model

- A binding connects a `poris_sys` with an `arch_node` in the **same project
  tree**. Identify endpoints by their CSIDs in the binding form.
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
then add parameter mappings and command policies. The binding page shows the
PORIS panel in the sidebar and the CAD viewer in the body. Configure PORIS and
use the selected trigger to apply accepted runtime values to that page's CAD.
Manual sliders remain available for inspection.

Motion is local to the current page, not broadcast to other users or tabs.
Neither the original geometry nor item defaults are changed. This is a
simulation, not hardware execution; MQTT, Godot, coupling formulas and motion
trajectories are not included.

## Installation and scope

Depends on cosmoSys >=0.2.8, Architecture >=0.1.3 and PORIS
>=0.2.4. Install under `plugins/cosmosys_zzporis_arch` so it loads after
its dependencies; the plugin ID is `cosmosys_poris_arch`.
After migrating its dependencies, run:

```sh
RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME=cosmosys_poris_arch
```

Restart Redmine, enable the integration and configure bindings for your model.
Choose conversions and label mappings explicitly; there are no assumed HOME,
PARK or TECH poses.

Permissions: `view_poris_arch` to inspect; `manage_poris_arch` and `edit_issues`
on both endpoint projects to edit (administrators allowed). Each runtime action
also checks endpoint visibility and PORIS access. Configure these deliberately
before granting access to other users.

**Current limitation:** the new integration binding tables are not yet included
in project snapshots/ODS. Existing PORIS and architectural CAD items continue to
roundtrip, but their integration bindings must currently be recreated. Keep
this limitation in mind when evaluating the optional deployment set; validate
your mappings before using imported or copied projects.

## License

Licensed under the GNU General Public License, version 3. See [LICENSE](LICENSE).
