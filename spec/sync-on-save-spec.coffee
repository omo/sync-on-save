fs = require 'fs'

{CompositeDisposable} = require 'atom'

SyncOnSave = require '../lib/sync-on-save'
CommandRunner = require '../lib/command-runner'
{FakeRunnerMaker} = require './utils'

describe "SyncOnSave", ->
  testEnablerPath = "/tmp/sync-on-save-test-enabler"
  testDotGitPath = "/tmp/sync-on-save-test-dot-git"
  testProjectRoot = "/tmp/sync-project-root"

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
    fs.mkdirSync(testProjectRoot) unless fs.existsSync(testProjectRoot)

    workspaceElement = atom.views.getView(atom.workspace)
    waitsForPromise ->
      atom.packages.activatePackage('sync-on-save').then (pack) ->
        target = pack

  afterEach ->
    subscriptions.dispose()

  describe "when the editor saves the buffer, sync is initiated", ->
    it "Trigger a file save.", ->
      runners = new FakeRunnerMaker()
      target.mainModule.syncer.makeRunner = runners.makePassingRunner.bind(runners)
      waitsForPromise ->
        target.mainModule.syncProject().then (r) ->
          expect(runners.getLength()).toBe 4

  describe "when sync failed", ->
    it "shows an error notification", ->
      CommandRunner.showTrace = true
      target.mainModule.syncer.getProjectRoot = -> testProjectRoot
      waitsForPromise -> target.mainModule.syncProject().then ->
        expect(addedNotifications.length).toBe 1
        expect(addedNotifications[0].getType()).toBe 'error'

  describe "when it is toggled", ->
    fakePaths = ->
      target.mainModule.syncer.getDotGitPath = -> testDotGitPath
      target.mainModule.syncer.getEnabler = -> testEnablerPath

    it "It creates or deletes a file.", ->
      fakePaths()
      waitsForPromise -> target.mainModule.enableSync().then ->
        expect(fs.existsSync(testEnablerPath)).toBe true
        expect(addedNotifications.length).toBe 1
        waitsForPromise -> target.mainModule.disableSync().then ->
          expect(fs.existsSync(testEnablerPath)).toBe false
          expect(addedNotifications.length).toBe 2

    it "Shows errors if dot-git dir isn't there.", ->
      fakePaths()
      fs.rmdirSync(testDotGitPath)
      waitsForPromise -> target.mainModule.enableSync().then ->
        expect(addedNotifications.length).toBe 1
        expect(addedNotifications[0].getType()).toBe 'error'

    it "Show errors even for disabling case.", ->
      fakePaths()
      fs.rmdirSync(testDotGitPath)
      waitsForPromise -> target.mainModule.disableSync().then ->
        expect(addedNotifications.length).toBe 1
        expect(addedNotifications[0].getType()).toBe 'error'
        expect(addedNotifications[0].getMessage()).toMatch 'git'
