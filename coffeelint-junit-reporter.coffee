_ = require 'lodash'
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
      errors: errors.length
      time: 0
  ]
  if errors.length
    errors.forEach (error) ->
      data.push
        _attr:
          name: "#{filename}:#{error.lineNumber} #{error.description}"
          classname: ""
          time: 0
      data.push
        failure:
          _cdata:
            error.description
  {testsuite: data}

module.exports = class CheckstyleReporter
    constructor: (@errorReport, @options = {}) ->
      @options.outFile = @options.outFile || process.env.COFFEELINT_JUNIT || 'lint-results.xml';

    publish: =>
      testsuites = _.map @errorReport.paths, summarize
      xmlData = xml({testsuites}, {declaration: true, indent: '  '})
      mkdirp.sync path.dirname(@options.outFile)
      fs.writeFileSync @options.outFile, xmlData, 'utf-8'
