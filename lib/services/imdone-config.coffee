# READY:0 This should manage access to all config settings id:23
pkg = require '../../package.json'

module.exports =
  getPackageName: () -> pkg.name

  getPackagePath: () -> atom.packages.getLoadedPackage(pkg.name).path

  getSettings: () -> atom.config.get "#{pkg.name}"
