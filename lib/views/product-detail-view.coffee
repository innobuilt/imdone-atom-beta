{$, $$, $$$, View} = require 'atom-space-pen-views'
util = require 'util'

module.exports =
class ProductDetailView extends View
  handleEvents: (@emitter)->
    if @initialized || !@emitter then return else @initialized = true
    # @on 'click', '#create-tasks', =>
    #   @emitter.emit 'tasks.create', @product.name

    @on 'click', '.enable-btn', =>
      return if @product.isEnabled()
      # READY:80 Connector plugin should be added
      @emitter.emit 'connector.enable', @product.connector

    @on 'click', '.disable-btn', =>
      return unless @product.isEnabled()
      # READY:90 Connector plugin should be removed
      @emitter.emit 'connector.disable', @product.connector

  @content: (params) ->
    require 'json-editor'
    @div class: 'product-detail-view-content config-container', =>
      @div outlet: '$detail'
      @div class: 'json-editor-container vertical-scroll', =>
        @div outlet: '$configEditor', class: 'json-editor native-key-bindings'

  setProduct: (@product)->
    return unless @product && @product.name
    @$detail.html @getDetail(@product)
    @$configEditor.empty()
    return unless @product.linked
    if @product.isEnabled() then @$configEditor.show() else @$configEditor.hide()
    @createEditor()

  createEditor: ->
    options =
      schema: @product.schemas.config # TODO:160 Rule schemas to be set by GET /projects/ :projectId/products +rules-workflow
      startval: @product.connector.config # TODO:170 Rule values to be set by GET /projects/ :projectId/products +rules
      theme: 'bootstrap3'
      required_by_default: true
      disable_edit_json: true
      disable_properties: true
      disable_collapse: true

    # TODO:50 Add provider configurations before creating editor
    @configEditor.destroy() if @configEditor
    @configEditor = new JSONEditor @$configEditor.get(0), options
    @configEditor.on 'change', => @emitChange()

  emitChange: ->
    _ = require 'lodash'
    editorVal = @configEditor.getValue()
    currentVal =  _.get(@product, 'connector.config')
    return if _.isEqual editorVal, currentVal
    _.set @product, 'connector.config', editorVal
    _.set @product, 'connector.name', @product.name
    @emitter.emit 'connector.change', @product

  # READY:40 Add enable checkbox and take appropriate actions on check/uncheck +urgent
  # READY:290 When unlinked disable all connectors (In API) +urgent
  getDetail: (product) ->
    $$ ->
      @h1 "#{product.name}"
      # TODO:180 This will have to be upadted on an event sent with pusher
      @div class:'block', =>
        if product.isLinked()
          @div class:'btn-group', =>
            selected = if product.isEnabled() then " selected" else ""
            @button class:"enable-btn btn#{selected}", 'ON'
            selected = unless product.isEnabled() then " selected" else ""
            @button class:"disable-btn btn#{selected}", 'OFF'
          @a href:product.logout, class:'btn icon icon-log-out inline-block-tight', "unlink your #{product.name} account"
          # @button id:'create-tasks', class:'btn icon icon icon-cloud-upload inline-block-tight', "create #{product.entity}s on #{product.name}"
        else
          @a href:product.login, class:'btn icon icon-log-in inline-block-tight', "link your #{product.name} account"