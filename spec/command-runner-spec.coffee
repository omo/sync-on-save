CommandRunner = require '../lib/command-runner'

describe "CommandRunner", ->

  describe "when run is invoked", ->
    it "executes the command given", ->
      waitsForPromise ->
        new CommandRunner("/", "ls", []).run().then (r) ->
          expect(r.code).toBe 0

    it "report the error from the command", ->
      waitsForPromise ->
        new CommandRunner("/", "false", []).run().then( ->
          expect(false).toBe true
        ).catch((r) ->
          expect(r.code).not.toBe 0
        )

    it "report the error from the Process class", ->
      waitsForPromise ->
        new CommandRunner("/", "no-such-file", []).run().then( ->
          expect(false).toBe true
        ).catch((r) ->
          expect(r.code).not.toBe 0
        )

  describe "when it needs workaround", ->
    it "runs bash", ->
      c = new CommandRunner("/", "echo", ["hello"])
      c._needsWorkaround = -> true
      expect(c.getCommand()).toBe "bash"
      expect(c.getArgs()).toEqual ["-c", "echo \"hello\""]

    it "escapes double quotes", ->
      c = new CommandRunner("/", "ls", ["\"My Document\""])
      c._needsWorkaround = -> true
      expect(c.getArgs()).toEqual ["-c", "ls \"\\\"My Document\\\"\""]

describe "CommandRunner.Fake", ->

  describe "when run is invoked", ->
    it "is shortly resolved", ->
      waitsForPromise ->
        target = new CommandRunner.Fake()
        target.setReturnCode(0)
        target.run().then (r) ->
          expect(r.code).toBe 0

    it "can fail for non-zero code", ->
      waitsForPromise ->
        target = new CommandRunner.Fake()
        target.setReturnCode(1)
        target.run().then((r) ->
          expect(true).toBe false
        ).catch((r) ->
          expect(r.code).toBe 1
        )
