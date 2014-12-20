fs = require 'fs'
path = require 'path'
Q = require 'q'

{CompositeDisposable, BufferedProcess} = require 'atom'
CommandRunner = require './command-runner'

module.exports = SyncOnSave =
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'sync-on-save:sync': => @syncProject()
    @subscriptions.add atom.commands.add 'atom-workspace', 'sync-on-save:enable-sync': => @enableSync()
    @subscriptions.add atom.commands.add 'atom-workspace', 'sync-on-save:disable-sync': => @disableSync()
    @subscriptions.add atom.workspace.observeTextEditors((editor) => @_editorGiven(editor))

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    {}

  syncProject: ->
    @sync(atom.project.rootDirectory.getPath())

  enableSync: ->
    @_createTouchFileIfNeeded().then( =>
      atom.notifications.addSuccess "Sync-to-Save is enabled."
    ).catch((e) =>
      atom.notifications.addError e
      Q(e)
    )

  disableSync: ->
    @_deleteTouchFileIfNeeded().then( =>
      atom.notifications.addSuccess "Sync-to-Save is disabled."
    ).catch((e) =>
      atom.notifications.addError e
      Q(e)
    )

  sync: (path) ->
    @_makeRunner(path, "git", ["add", "."]).run(
    ).then(
      # FIXME: Pass meaningful commit message.
      => @_makeRunner(path, "git", ["commit", "-m", "Sync."]).run()
    ).then(
      => @_makeRunner(path, "git", ["pull"]).run()
    ).then(
      => @_makeRunner(path, "git", ["push"]).run()
    ).then(
      => 0
    ).catch((res) =>
      # FIXME: Notify user properly.
      console.log(res.stderr.join("\n"))
      Q(res)
    )

  getDotGitPath: ->
    path.join(atom.project.rootDirectory.getPath(), ".git")

  getEnabler: ->
    path.join(atom.project.rootDirectory.getPath(), ".git", "sync-on-save")

  _createTouchFileIfNeeded: ->
    d = Q.defer()
    enabler = @getEnabler()
    fs.exists @getDotGitPath(), (fe)=>
      return d.reject(".git directory is not found") unless fe
      fs.exists enabler, (e) =>
        fs.open(enabler, 'w', -> d.resolve()) unless e
    d.promise

  _deleteTouchFileIfNeeded: ->
    d = Q.defer()
    fs.exists @getDotGitPath(), (fe)=>
      return d.reject(".git directory is not found") unless fe
      enabler = @getEnabler()
      fs.exists enabler, (e) =>
        fs.unlink(enabler, -> d.resolve()) if e
    d.promise

  _editorGiven: (editor) ->
    @subscriptions.add editor.onDidSave () =>
      enabler = @getEnabler()
      fs.exists(enabler, (exist) =>
        @syncProject() if exist
      )

  _makeRunner: (cwd, cmd, args) ->
    new CommandRunner(cwd, cmd, args)
