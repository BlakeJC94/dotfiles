# pi-reload

A local Herdr plugin action that previews idle or done Pi agents across all local Herdr workspaces and, after confirmation, submits `/reload` to them.

## Link and use

~~~sh
herdr plugin link ~/.config/herdr/plugins/pi-reload
herdr plugin action invoke blake.pi-reload.reload
~~~

The action opens a popup showing reloadable and skipped sessions, grouped by workspace ID, before asking for confirmation. It rechecks each candidate's workspace, Pi agent kind, and idle/done status immediately before submitting. Working, blocked, unknown, and non-Pi agents are not targeted. It covers all workspaces on this local Herdr server; remote Herdr machines are out of scope.

Requires `bash` and `jq`.
