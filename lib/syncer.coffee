fs = require 'fs'
path = require 'path'
Q = require 'q'

CommandRunner = require './command-runner'

module.exports = class Syncer
  runSyncCommands: (path) ->
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
    )

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

  _makeRunner: (cwd, cmd, args) ->
    new CommandRunner(cwd, cmd, args)
