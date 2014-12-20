fs = require 'fs'

{CompositeDisposable} = require 'atom'

SyncOnSave = require '../lib/sync-on-save'
CommandRunner = require '../lib/command-runner'

describe "SyncOnSave", ->
  testEnablerPath = "/tmp/sync-on-save-test-enabler"
  testDotGitPath = "/tmp/sync-on-save-test-dot-git"

  [workspaceElement, target, subscriptions, addedNotifications] = []

  beforeEach ->
    subscriptions = new CompositeDisposable
    addedNotifications = []
    subscriptions.add(atom.notifications.onDidAddNotification (n) ->
      addedNotifications.push(n)
    )

    fs.rmdirSync(testDotGitPath) if fs.existsSync(testDotGitPath)
    fs.mkdirSync(testDotGitPath)
    fs.unlinkSync(testEnablerPath) if fs.existsSync(testEnablerPath)
    workspaceElement = atom.views.getView(atom.workspace)
    waitsForPromise ->
      atom.packages.activatePackage('sync-on-save').then (pack) ->
        target = pack

  afterEach ->
    subscriptions.dispose()

  describe "when the editor saves the buffer, sync is initiated", ->
    it "Trigger a file save.", ->
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
      target.mainModule.getDotGitPath = -> testDotGitPath
      target.mainModule.getEnabler = -> testEnablerPath
      waitsForPromise -> target.mainModule.enableSync().then ->
        expect(fs.existsSync(testEnablerPath)).toBe true
        expect(addedNotifications.length).toBe 1
        waitsForPromise -> target.mainModule.disableSync().then ->
          expect(fs.existsSync(testEnablerPath)).toBe false
          expect(addedNotifications.length).toBe 2

    it "Shows errors if dot-git dir isn't there.", ->
      fs.rmdirSync(testDotGitPath)
      waitsForPromise -> target.mainModule.enableSync().then ->
        expect(addedNotifications.length).toBe 1
        expect(addedNotifications[0].getType()).toBe 'error'

    it "Show errors even for disabling case.", ->
      fs.rmdirSync(testDotGitPath)
      waitsForPromise -> target.mainModule.disableSync().then ->
        expect(addedNotifications.length).toBe 1
        expect(addedNotifications[0].getType()).toBe 'error'
        expect(addedNotifications[0].getMessage()).toMatch 'git'
