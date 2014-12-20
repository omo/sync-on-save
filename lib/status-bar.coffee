
class StatusBarSyncOnSaveBase extends HTMLElement
  initialize: ->
    @classList.add('inline-block')
    @shadow = @createShadowRoot()

  willSync: ->
    @shadow.innerHTML = "Syncing..."

  didSync: ->
    @shadow.innerHTML = ""

  createdCallback: ->
    @initialize()

module.exports.StatusBarSyncOnSave = document.registerElement("status-save-on-sync", prototype: StatusBarSyncOnSaveBase.prototype)
