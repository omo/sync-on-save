
Syncer = require '../lib/syncer'
{FakeRunnerMaker} = require './utils'

describe "Syncer", ->
  describe "when it does sync", ->
    it "emits a couple of events", ->
      willSyncCount = 0
      didSyncCount = 0
      runners = new FakeRunnerMaker()
      syncer = new Syncer()
      syncer.onWillSync -> willSyncCount++
      syncer.onDidSync -> didSyncCount++

      syncer.makeRunner = runners.makePassingRunner.bind(runners)
      waitsForPromise ->
        syncer.runSyncCommands("/").then ->
          expect(willSyncCount).toBe 1
          expect(didSyncCount).toBe 1
