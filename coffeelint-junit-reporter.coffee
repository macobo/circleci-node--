_ = require 'lodash'
CoffeelintDefaultReporter = require 'coffeelint/lib/reporters/default'
fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
xml = require 'xml'

singleTestCase = (filename, error) ->
  testcase = [
    _attr:
      name: filename
      classname: filename
      time: 0
  ]
  if error?
    testcase[0]._attr.name += ":#{error.lineNumber}"
    testcase.push
      failure:
        _cdata: "(#{error.level}) #{filename}:#{error.lineNumber} #{error.description}"

  {testcase}

createTestCases = (errors, filename) ->
  if errors.length is 0
    [singleTestCase filename]
  else
    errors.map (error) -> singleTestCase filename, error

summarize = (paths) ->
  failures = _.sumBy _.values(paths), (errors) -> errors.length
  total = _.sumBy _.values(paths), (errors) -> Math.max(1, errors.length)
  description =
    name: 'coffeelint'
    time: 0
    timestamp: new Date().toISOString().slice(0, -5)
    tests: total
    failures: failures

  testsuite = _(paths)
    .map createTestCases
    .flatten()
    .unshift {_attr: description}
    .value()

  testsuite

module.exports = class CheckstyleReporter
    constructor: (@errorReport, @options = {}) ->
      @defaultReporter = new CoffeelintDefaultReporter @errorReport, {quiet: true, colorize: true}
      @options.outFile = @options.outFile || process.env.COFFEELINT_JUNIT || 'lint-results.xml';

    publish: =>
      @defaultReporter.publish()
      relevantPaths = _.mapValues @errorReport.paths, (errors) ->
        _.filter errors, ({level}) -> level is 'error'
      testsuite = summarize relevantPaths
      testsuites = [
        _attr: testsuite[0]._attr
      ,
        {testsuite}
      ]
      xmlData = xml({testsuites}, {declaration: true, indent: '  '})
      mkdirp.sync path.dirname(@options.outFile)
      fs.writeFileSync @options.outFile, xmlData, 'utf-8'
