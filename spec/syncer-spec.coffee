
Q = require 'q'

Syncer = require '../lib/syncer'
{FakeRunnerMaker} = require './utils'

describe "Syncer", ->
  [runners, syncer] = []

  describe "when it does sync", ->
    beforeEach ->
      runners = new FakeRunnerMaker()
      syncer = new Syncer()

    fakeSyncer = ->
      syncer.makeRunner = runners.makePassingRunner.bind(runners)
      syncer.getChangedFiles = -> Q(["hello.js"])

    it "emits a couple of events", ->
      willSyncCount = 0
      didSyncCount = 0
      syncer.onWillSync -> willSyncCount++
      syncer.onDidSync -> didSyncCount++
      fakeSyncer()

      waitsForPromise ->
        syncer.runSyncCommands("/").then ->
          expect(willSyncCount).toBe 1
          expect(didSyncCount).toBe 1

    it "the isSyncing flag is true", ->
      fakeSyncer()
      waitsForPromise ->
        p = syncer.runSyncCommands("/")
        expect(syncer.isSyncing()).toBe true
        p.then ->
          expect(syncer.isSyncing()).toBe false

    it "doesn't run another sync", ->
      fakeSyncer()
      p1 = syncer.runSyncCommandsIfPossible("/")
      p2 = syncer.runSyncCommandsIfPossible("/")
      waitsForPromise ->
        p1.then (r) ->
          console.log(r)
          expect(runners.getLength()).toBe 4

    describe "getChangedFiles", ->
      it "works", ->
        syncer.makeRunner = runners.makePassingRunnerWithStdout.bind(runners, ["foo.js\n", "bar/baz.js\n"])
        waitsForPromise ->
          syncer.getChangedFiles().then (lines) =>
            expect(lines).toEqual ["foo.js", "baz.js"]

    describe "createCommitMessage", ->
      it "uses only the filename if there is one file.", ->
        expect(syncer.createCommitMessage(["hello.js"])).toEqual "Updated hello.js."
      it "adds the numbrer of file if there are more than one files", ->
        expect(syncer.createCommitMessage(["hello.js", "bye.js"])).toEqual "Updated hello.js and 1 file(s)."
