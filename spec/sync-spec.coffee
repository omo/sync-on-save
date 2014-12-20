
Syncer = require '../lib/syncer'
{FakeRunnerMaker} = require './utils'

describe "Syncer", ->
  [runners, syncer] = []

  describe "when it does sync", ->
    beforeEach ->
      runners = new FakeRunnerMaker()
      syncer = new Syncer()

    it "emits a couple of events", ->
      willSyncCount = 0
      didSyncCount = 0
      syncer.onWillSync -> willSyncCount++
      syncer.onDidSync -> didSyncCount++
      syncer.makeRunner = runners.makePassingRunner.bind(runners)

      waitsForPromise ->
        syncer.runSyncCommands("/").then ->
          expect(willSyncCount).toBe 1
          expect(didSyncCount).toBe 1

    it "the isSyncing flag is true", ->
      syncer.makeRunner = runners.makePassingRunner.bind(runners)
      waitsForPromise ->
        p = syncer.runSyncCommands("/")
        expect(syncer.isSyncing()).toBe true
        p.then ->
          expect(syncer.isSyncing()).toBe false

    it "doesn't run another sync", ->
      syncer.makeRunner = runners.makePassingRunner.bind(runners)
      p1 = syncer.runSyncCommandsIfPossible("/")
      p2 = syncer.runSyncCommandsIfPossible("/")
      waitsForPromise ->
        p1.then (r) ->
          console.log(r)
          expect(runners.getLength()).toBe 4
