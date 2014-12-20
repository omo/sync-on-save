{BufferedProcess} = require 'atom'
# https://discuss.atom.io/t/support-for-es6-promise/11458
# Atom doesn't use the buildt-in Promise :-(
Q = require('q')

class CommandRunner
  @showTrace = false

  constructor: (@cwd, @command, @args) ->
    @stdoutLines = []
    @stderrLines = []

  run: ->
    d = Q.defer()
    p = new BufferedProcess
      options:
        cwd: @cwd
      command: @command
      args: @args
      stderr: (line) =>
        @_trace(line)
        @stderrLines.push(line)
      stdout: (line) =>
        @_trace(line)
        @stdoutLines.push(line)
      exit: (code) =>
        @_doneWith(d, code)
    p.onWillThrowError (ev) =>
      ev.handle()
      d.reject(@_makeResult(undefined))
    d.promise

  _makeResult: (code) ->
    { self: this, args: @args, code: code, stdout: @stdoutLines, stderr: @stderrLines }

  _doneWith: (deferred, code) ->
    if 0 == code
      deferred.resolve(@_makeResult(code))
    else
      deferred.reject(@_makeResult(code))

  _trace: (line) ->
    #if @showTrace
      console.log(line)


class FakeCommandRunner extends CommandRunner
  setReturnCode: (code) ->
    @returnCode = code

  run: ->
    d = Q.defer()
    process.nextTick =>
      if null == @returnCode
        throw "@returnCode should be set!"
      @_doneWith(d, @returnCode)
    d.promise

CommandRunner.Fake = FakeCommandRunner


module.exports = CommandRunner
