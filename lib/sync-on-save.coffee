{CompositeDisposable, BufferedProcess} = require 'atom'
fs = require 'fs'
path = require 'path'

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
    enabler = @getEnabler()
    fs.exists(enabler, (e) => fs.openSync(enabler, 'w') unless e)

  disableSync: ->
    enabler = @getEnabler()
    fs.exists(enabler, (e) => fs.unlinkSync(enabler) if e)

  sync: (path) ->
    # FIXME: Pass meaningful commit message.
    @_runGit(
      path, ["add", "."]
    ).then(
      => @_runGit(path, ["commit", "-m", "Sync."])
    ).then(
      => @_runGit(path, ["pull"])
    ).then(
      => @_runGit(path, ["push"])
    ).then(
      => 0 # FIXME: Show toast-like notification
    ).catch((res) =>
      # FIXME: Notify user properly.
      console.log(res.stderr.join("\n"))
    )

  getEnabler: ->
    path.join(atom.project.rootDirectory.getPath(), ".git", "sync-on-save")

  _editorGiven: (editor) ->
    @subscriptions.add editor.onDidSave () =>
      enabler = @getEnabler()
      fs.exists(enabler, (exist) =>
        @syncProject() if exist
      )

  _runGit: (cwd, args) ->
    return new Promise((res, rej) =>
      stdoutLines = []
      stderrLines = []
      new BufferedProcess(
        options:
          cwd: cwd
        command: "git"
        args: args
        stderr: (line) =>
          @_trace(line)
          stderrLines.push(line)
        stdout: (line) =>
          @_trace(line)
          stdoutLines.push(line)
        exit: (code) =>
          if 0 == code
            res(args: args, code: code, stdout: stdoutLines, stderr: stderrLines)
          else
            rej(args: args, code: code, stdout: stdoutLines, stderr: stderrLines)
      ))

  _trace: (line) ->
    console.log(line)
