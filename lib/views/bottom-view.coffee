{$, $$, $$$, View, TextEditorView} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
config = require '../services/imdone-config'

module.exports =
class BottomView extends View
  constructor: ({@imdoneRepo, @path, @uri}) ->
    super
    @client = require('../services/imdoneio-client').instance


  @content: (params) ->
    LoginView = require './login-view'
    ShareTasksView = require './share-tasks-view'
    # ProjectSettingsView = require './project-settings-view'
    @div class:'imdone-bottom-view', =>
      @div class:'bottom-view-header', =>
        @div outlet: 'resizer', class:'split-handle-y'
        @div outlet: 'closeButton', class:'close-button', =>
          @raw '&times;'
        # DONE:0 Set up a global messaging area. +enhancement gh:159 id:55
        @div outlet: 'error', class:'alert alert-error highlight-error text-center'
      @div class:'bottom-view-main zoomable', =>
        # @div outlet: 'projectSettings', class:'project-settings config-panel', =>
        #   @subview 'projectSettingsView', new ProjectSettingsView params
        @div outlet: 'shareTasks', class:'share-tasks config-panel', =>
          @subview 'shareTasksView', new ShareTasksView params
        @div outlet: '$login', class: 'config-panel', =>
          @subview 'loginView', new LoginView params
        @div outlet: 'renameList', class:'rename-list config-panel', =>
          @h2 =>
            @span outlet:'renameListLabel'
          @div class: 'block', =>
            @div class: 'input-small', =>
              @subview 'renameListField', new TextEditorView(mini: true)
            @button click: 'hide', class:'inline-block-tight btn', 'Forget it'
            @button click: 'doListRename', class:'inline-block-tight btn btn-primary', 'Looks good'
        @div outlet: 'newList', class:'new-list config-panel', =>
          @h2 'New List'
          @div class: 'block', =>
            @div class: 'input-small', =>
              @subview 'newListField', new TextEditorView(mini: true)
            @button click: 'hide', class:'inline-block-tight btn', 'Forget it'
            @button click: 'doNewList', class:'inline-block-tight btn btn-primary', 'Looks good'
        @div outlet: 'plugins', class:'imdone-plugins-container config-panel'

  handleEvents: (@emitter)->
    if @initialized || !@emitter then return else @initialized = true
    @loginView.handleEvents @emitter
    @shareTasksView.handleEvents @emitter
    # @projectSettingsView.handleEvents @emitter

    # #DONE:0 Make resizable when open [Edit fiddle - JSFiddle](http://jsfiddle.net/3jMQD/614/) id:56
    startY = startHeight = null
    container = this
    @resizer.on 'mousedown', (e) =>
      e.stopPropagation()
      e.preventDefault()
      container.emitter.emit 'resize.start'
      startY = e.clientY
      startHeight = container.height()
      $imdoneAtom = container.closest('.pane-item')
      doDrag = (e) =>
        e.preventDefault()
        e.stopPropagation()
        height = startHeight + startY - e.clientY
        container.height(height)
        container.emitter.emit 'resize.change', height

      stopDrag = (e) =>
        container.emitter.emit 'resize.stop'
        $imdoneAtom.off 'mousemove', doDrag
        $imdoneAtom.off 'mouseup', stopDrag

      $imdoneAtom.on 'mousemove', doDrag
      $imdoneAtom.on 'mouseup', stopDrag

    @newListField.on 'keyup', (e) =>
      code = e.keyCode || e.which
      @doNewList() if code == 13
      true

    @renameListField.on 'keyup', (e) =>
      code = e.keyCode || e.which
      @doListRename() if code == 13
      true

    @on 'keyup', (e) =>
      code = e.keyCode || e.which
      @hide() if code == 27
      true

    @emitter.on 'list.modified', (list) => @hide()

    @emitter.on 'project.not-found', => @showShare()

    # @emitter.on 'project.found', => @hide()

    @closeButton.on 'click', => @hide()

    @emitter.on 'authenticated', => @$login.hide()

    @emitter.on 'unauthenticated', =>
      @hide() unless config.getSettings().showLoginOnLaunch
      @showLogin() if config.getSettings().showLoginOnLaunch

    # DONE:0 This belongs in bottomView +refactor gh:144 id:57
    @emitter.on 'list.new', => @showNewList()

    # DONE:0 This belongs in bottomView +refactor gh:143 id:58
    @emitter.on 'share', => @showShare()

    @emitter.on 'login', => @showLogin()

    # @emitter.on 'project.settings', => @showProjectSettings()

    @emitter.on 'project.removed', => @hide()

    @emitter.on 'menu.toggle', => @toggleClass 'shift'

    @emitter.on 'error', ($html) => @error.html($html).show()

    @emitter.on 'error.hide', => @error.hide()

  isOpen: ->
    @hasClass 'open'

  show: ->
    unless @isOpen()
      @error.hide()
      @emitter.emit 'config.open'
      @addClass 'open'
      # @removeClass 'hidden'

  hide: ->
    @find('.config-panel').hide()
    if @isOpen()
      @error.empty()
      @removeClass 'open'
      # @addClass 'hidden'
      @css 'height', ''
      @emitter.emit 'config.close'

  setHeight: (px) ->
    @height(px)
    @emitter.emit 'resize.change', px

  addPlugin: (plugin) ->
    pluginView = plugin.getView()
    pluginView.addClass "imdone-plugin #{plugin.constructor.pluginName}"
    pluginView.appendTo @plugins
    # plugin.on 'view.show', => @showPlugin plugin

  removePlugin: (plugin) ->
    plugin.getView().remove()

  showPlugin: (plugin) ->
    @hide()
    @plugins.find('.imdone-plugin').hide()
    @plugins.find(".#{plugin.constructor.pluginName}").show()
    @plugins.show()
    @show()

  # TODO:0 DRY these show... methods up id:59
  showShare: () ->
    @hide()
    @shareTasks.show () => @shareTasksView.show()
    @setHeight(500)
    @show()

  showLogin: () ->
    @hide()
    @$login.show () => @loginView.show()
    @setHeight(500)
    @show()

  # showProjectSettings: () ->
  #   @hide()
  #   @projectSettings.show () => @projectSettingsView.show()
  #   @setHeight(500)
  #   @show()

  showRename: (name) ->
    @hide()
    @renameListLabel.text 'Rename '+name
    @listToRename = name
    @renameListField.getModel().setText name
    @renameListField.getModel().selectAll()
    @renameList.show()
    @setHeight(200)
    @show()
    @renameListField.focus()

  getRenameList: ->
    @renameListField.getModel().getText()

  editListName: (name) ->
    @showRename name

  doListRename: ->
    return unless @listOk @getRenameList()
    @imdoneRepo.renameList @listToRename, @getRenameList()
    @hide()

  showNewList: ->
    @hide()
    @newListField.getModel().setText ''
    @newList.show()
    @setHeight(200)
    @show()
    @newListField.focus()

  getNewList: ->
    @newListField.getModel().getText()

  addList: ->
    @showNewList()

  doNewList: ->
    return unless @listOk @getNewList()
    @hide()
    @imdoneRepo.addList(name: @getNewList(), hidden:false)

  listOk: (name) ->
    return true if /^[\w\-]+$/.test(name)
    @error.html('List name can only contain letters, numbers , dashes and underscores')
    false
