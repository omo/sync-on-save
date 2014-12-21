# Sync-on-Save package for Atom

This package provides a save-time hook that bluntly does `add`, `commit` and `push` your changes to its Git repository. Sync-on-save allows you to use GitHub as a DropBox-like storage ... whose contents are mainly edited through Atom editor.

You can (and have to) enable the hook for each checkout that you want to "sync". There is a few commands to control the switch.

 * `Sync On Save: Enable Sync` to turn it on,
 * `Sync On Save: Disable Sync` to turn it off and
 * 'Sync On Save: Start Syncing' to force the sync.

Note that the switch is saved as `.git/sync-on-save` file.

The sync can fail if there are conflicts. To make it work again, you can manually resolve the conflict.
