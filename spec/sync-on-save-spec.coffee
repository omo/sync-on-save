fs = require 'fs'

SyncOnSave = require '../lib/sync-on-save'
CommandRunner = require '../lib/command-runner'

describe "SyncOnSave", ->
  testEnablerPath = "/tmp/sync-on-save-test-enabler"
  [workspaceElement, target] = []

  beforeEach ->
    fs.unlinkSync(testEnablerPath) if fs.existsSync(testEnablerPath)
    workspaceElement = atom.views.getView(atom.workspace)
    waitsForPromise ->
      atom.packages.activatePackage('sync-on-save').then (pack) ->
        target = pack

  describe "when the editor saves the buffer, sync is initiated", ->
    it "Trigger a file save.", ->
      runs ->
        runners = []
        target.mainModule._makeRunner = (cwd, cmd, args) ->
          console.log(args)
          fake = new CommandRunner.Fake(cwd, cmd, args)
          fake.setReturnCode(0)
          runners.push(runners)
          fake
        waitsForPromise ->
          target.mainModule.syncProject().then (r) ->
            expect(runners.length).toBe 4

  describe "when it is toggled", ->
    it "It creates or deletes a file.", ->
      runs ->
        target.mainModule.getEnabler = -> testEnablerPath
        waitsForPromise -> target.mainModule.enableSync().then ->
          expect(fs.existsSync(testEnablerPath)).toBe true
          waitsForPromise -> target.mainModule.disableSync().then ->
            expect(fs.existsSync(testEnablerPath)).toBe false
