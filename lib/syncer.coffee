fs = require 'fs'
path = require 'path'
Q = require 'q'
{EventEmitter} = require('events')

CommandRunner = require './command-runner'

module.exports = class Syncer
  constructor: ->
    @emitter = new EventEmitter()

  runSyncCommands: (path = @getProjectRoot()) ->
    @emitter.emit('will-sync')
    @makeRunner(path, "git", ["add", "."]).run(
    ).then( =>
      # FIXME: Pass meaningful commit message.
      @makeRunner(path, "git", ["commit", "-m", "Sync."]).run()
    ).then( =>
      @makeRunner(path, "git", ["pull"]).run()
    ).then( =>
      @makeRunner(path, "git", ["push"]).run()
    ).fin( =>
      @emitter.emit('did-sync')
    )

  onWillSync: (l) -> @emitter.on('will-sync', l)
  onDidSync: (l) -> @emitter.on('did-sync', l)

  getProjectRoot: -> atom.project.rootDirectory.getPath()
  getDotGitPath: -> path.join(atom.project.rootDirectory.getPath(), ".git")
  getEnabler: -> path.join(atom.project.rootDirectory.getPath(), ".git", "sync-on-save")

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
