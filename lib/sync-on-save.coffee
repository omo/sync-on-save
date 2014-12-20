fs = require 'fs'
path = require 'path'
Q = require 'q'

{CompositeDisposable} = require 'atom'
Syncer = require './syncer'
{StatusBarSyncOnSave} = require './status-bar'

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

    atom.packages.onDidActivateAll =>
      @statusBar = document.querySelector("status-bar")
      e = new StatusBarSyncOnSave()
      @syncer.onWillSync(e.willSync.bind(e))
      @syncer.onDidSync(e.didSync.bind(e))
      @statusBar?.addRightTile(item: e, priority: 100)

  deactivate: ->
    @subscriptions.dispose()
    # FIXME: Remove status bar item.a

  serialize: ->
    {}

  syncProject: ->
    @_handleSyncResult(@syncer.runSyncCommands())

  enableSync: ->
    @syncer.createTouchFileIfNeeded().then(=>
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
      @syncer.shouldEnable().then (p) =>
        @syncProject() if p

  _handleSyncResult: (p) ->
    p.catch (res) =>
      return if res.stdout.join("").match("working directory clean")
      stderrText = "Git error #{res.cwd} #{res.args.join(' ')}: \n" + res.stderr.join("\n")
      console.log(stderrText)
      atom.notifications.addError stderrText
      Q(res)
