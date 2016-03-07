_ = require 'lodash'
CoffeelintDefaultReporter = require 'coffeelint/lib/reporters/default'
fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
xml = require 'xml'

summarize = (errors, filename) ->
  data = [
    _attr:
      name: filename,
      file: filename
      timestamp: new Date().toISOString().slice(0, -5)
      tests: errors.length
      failures: errors.length
      time: 0
  ]
  if errors.length
    errors.forEach (error) ->
      data.push
        _attr:
          name: "#{filename}:#{error.lineNumber} #{error.description}"
          classname: error.context
          time: 0
      data.push
        failure:
          _cdata:
            error.description
  {testsuite: data}

module.exports = class CheckstyleReporter
    constructor: (@errorReport, @options = {}) ->
      @defaultReporter = new CoffeelintDefaultReporter @errorReport, {quiet: true, colorize: true}
      @options.outFile = @options.outFile || process.env.COFFEELINT_JUNIT || 'lint-results.xml';

    publish: =>
      @defaultReporter.publish()
      testsuites = _(@errorReport.paths)
        .mapValues (errors) ->
          _.filter errors, ({level}) -> level is 'error'
        .map summarize
        .value()
      testsuites.unshift
        _attr:
          name: 'coffeelint'
          timestamp: new Date().toISOString().slice(0, -5)
          tests: _.size @errorReport.paths
          time: 0
          failures: _.sumBy testsuites, ({testsuite}) -> testsuite[0]._attr.failures
      xmlData = xml({testsuites}, {declaration: true, indent: '  '})
      mkdirp.sync path.dirname(@options.outFile)
      fs.writeFileSync @options.outFile, xmlData, 'utf-8'
