_ = require 'lodash'
helper = require './imdone-helper'
log = require('debug/browser') 'imdone-atom:connector-manager'

module.exports =
class ConnectorManager
  constructor: (@repo) ->

  client: ->
    require('./imdoneio-client').instance

  getConnectors: (cb) ->
    @client().getProducts (err, products) =>
      log 'products:', products
      return cb err if err
      # READY:10 Add connector data from .imdone/config.json
      # DOING: connectors data should be read remotely and config.json used as a backup if error
      connectors = _.get @repo.getConfig(), 'connectors'
      return cb null, products unless connectors
      products.forEach (product) =>
        connector = connectors[product.name]
        return unless connector
        product.connector = connector
      cb null, products

  saveConnector: (product) ->
    _.set @repo.getConfig(), "connectors.#{product.name}", product.connector
    @repo.saveConfig()
    # DOING: connectors data should be stored remotely and config.json used as a backup


  getGitOrigin: () ->
    repo = helper.repoForPath @repo.getPath()
    debugger
    return null unless repo
    repo.getOriginURL()
