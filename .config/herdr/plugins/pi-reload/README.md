# pi-reload

A local Herdr plugin action that previews Pi agents in the current workspace and, after confirmation, submits `/reload` to those still idle or done.

## Link and use

~~~sh
herdr plugin link ~/.config/herdr/plugins/pi-reload
herdr plugin action invoke blake.pi-reload.reload
~~~

The action opens a popup showing reloadable and skipped sessions before asking for confirmation. It rechecks each candidate immediately before submitting. Working, blocked, unknown, and non-Pi agents are not targeted; other workspaces and remote machines are out of scope.

Requires `bash` and `jq`.
