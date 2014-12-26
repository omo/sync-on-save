fs = require 'fs'
path = require 'path'
Q = require 'q'
{EventEmitter} = require('events')

CommandRunner = require './command-runner'

module.exports = class Syncer
  NO_NEED_TO_CHANGE: "No need to change"

  constructor: ->
    @emitter = new EventEmitter()
    @_isSyncing = false

  runSyncCommandsIfPossible: (cwd = @getProjectRoot()) ->
    return Q(0) if @isSyncing()
    @runSyncCommands(cwd)

  runSyncCommands: (cwd = @getProjectRoot()) ->
    @_isSyncing = true
    @emitter.emit('will-sync')
    @makeRunner(cwd, "git", ["add", "."]).run(
    ).then( =>
      @getChangedFiles(cwd)
    ).then( (filenames) =>
      if 0 == filenames.length
        throw @NO_NEED_TO_CHANGE
      @makeRunner(cwd, "git", ["commit", "-m", @createCommitMessage(filenames)]).run()
    ).then( =>
      @makeRunner(cwd, "git", ["pull"]).run()
    ).then( =>
      @makeRunner(cwd, "git", ["push"]).run()
    ).catch((e) =>
      console.log(e)
      return Q(0) if (e == @NO_NEED_TO_CHANGE)
      throw e
    ).fin( =>
      @_isSyncing = false
      @emitter.emit('did-sync')
    )

  createCommitMessage: (filenames) ->
    if 1 < filenames.length
      "Updated #{filenames[0]} and #{filenames.length - 1} file(s)."
    else
      "Updated #{filenames[0]}."

  getChangedFiles: (cwd) ->
    @makeRunner(cwd, "git", ["diff", "--name-only", "HEAD"]).run().then (r) => r.stdout.map (l) -> path.basename(l).replace(/\n/, "")

  onWillSync: (l) -> @emitter.on('will-sync', l)
  onDidSync: (l) -> @emitter.on('did-sync', l)

  getProjectRoot: -> atom.project.rootDirectory.getPath()
  getDotGitPath: -> path.join(atom.project.rootDirectory.getPath(), ".git")
  getEnabler: -> path.join(atom.project.rootDirectory.getPath(), ".git", "sync-on-save")
  isSyncing: -> @_isSyncing

  shouldEnable: ->
    d = Q.defer()
    fs.exists(@getEnabler(), (pred) -> d.resolve(pred))
    d.promise

  createTouchFileIfNeeded: ->
    d = Q.defer()
    enabler = @getEnabler()
    fs.exists @getDotGitPath(), (fe)=>
      return d.reject(".git directory is not found") unless fe
      fs.exists enabler, (e) =>
        fs.open(enabler, 'w', -> d.resolve()) unless e
    d.promise

  deleteTouchFileIfNeeded: ->
    d = Q.defer()
    fs.exists @getDotGitPath(), (fe)=>
      return d.reject(".git directory is not found") unless fe
      enabler = @getEnabler()
      fs.exists enabler, (e) =>
        fs.unlink(enabler, -> d.resolve()) if e
    d.promise

  makeRunner: (cwd, cmd, args) ->
    new CommandRunner(cwd, cmd, args)
