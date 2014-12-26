CommandRunner = require '../lib/command-runner'

module.exports.FakeRunnerMaker = class FakeRunnerMaker
  constructor: ->
    @list = []

  makePassingRunner: (cwd, cmd, args) ->
    fake = new CommandRunner.Fake(cwd, cmd, args)
    fake.setReturnCode(0)
    @list.push(fake)
    fake

  makePassingRunnerWithStdout: (stdout, cwd, cmd, args) ->
    fake = @makePassingRunner(cwd, cmd, args)
    fake.setStdout(stdout)
    fake

  getLength: -> @list.length
