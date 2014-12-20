fs = require 'fs'
path = require 'path'
Q = require 'q'

{CompositeDisposable} = require 'atom'
Syncer = require './syncer'

module.exports = SyncOnSave =
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'sync-on-save:sync': => @syncProject()
    @subscriptions.add atom.commands.add 'atom-workspace', 'sync-on-save:enable-sync': => @enableSync()
    @subscriptions.add atom.commands.add 'atom-workspace', 'sync-on-save:disable-sync': => @disableSync()
    @subscriptions.add atom.workspace.observeTextEditors((editor) => @_editorGiven(editor))
    @syncer = new Syncer()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    {}

  syncProject: ->
    @_sync(@syncer.getProjectRoot())

  enableSync: ->
    @syncer.createTouchFileIfNeeded().then( =>
      atom.notifications.addSuccess "Sync-to-Save is enabled."
    ).catch((e) =>
      atom.notifications.addError e
      Q(e)
    )

  disableSync: ->
    @syncer.deleteTouchFileIfNeeded().then( =>
      atom.notifications.addSuccess "Sync-to-Save is disabled."
    ).catch((e) =>
      atom.notifications.addError e
      Q(e)
    )

  _editorGiven: (editor) ->
    @subscriptions.add editor.onDidSave =>
      @syncer.shouldSync().then =>
        @syncProject()

  _sync: (root) ->
    @syncer.runSyncCommands(root).catch (res) =>
      stderrText = "Git error:\n" + res.stderr.join("\n")
      console.log(stderrText)
      atom.notifications.addError stderrText
      Q(res)
