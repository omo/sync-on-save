# Sync-on-Save package for Atom

This package provides a save-time hook that bluntly does `add`, `commit` and `push` your changes to its Git repository. Sync-on-save allows you to use GitHub as a DropBox-like storage ... whose contents are mainly edited through Atom editor.

You can (and have to) enable the hook for each checkout that you want to "sync". There is a couple of commands to turn the switch.

 * `Sync On Save: Enable Sync`
 * `Sync On Save: Disable Sync`

 The switch is saved as `.git/sync-on-save` file.

 The sync can fail if there are conflicts. To make it work again, you can manually resolve the conflict.
