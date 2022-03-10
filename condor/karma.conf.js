'use strict';

// https://github.com/karma-runner/karma/blob/v0.13.4/docs/config/01-configuration-file.md
var cheerio = require('cheerio');
var glob = require('glob');
var path = require('path');
var argv = require('minimist')(process.argv.slice(2));
var fs = require('fs');
var pathHelper = require('path');

module.exports = function(config) {
    var baseFolder = argv.dist ? 'dist' : 'client';
    var settings = {
        basePath: path.join(__dirname, 'client'),
        frameworks: ['jasmine'],
        files: loadFiles(baseFolder, !argv.dist),
        preprocessors: {
            '**/*.html': ['ng-html2js'],
            '**/!(ng|signin)/!(*spec|*mock).js': ['coverage']
        },
        browsers: ['ChromeHeadlessCustom'], //'Chrome', '' 'ChromeDebugging'
        reporters: ['spec'],
        coverageReporter: {
            type: 'json',
            dir: path.join(__dirname, '/coverage/jsCoverage')
        },
        specReporter: {
            suppressSkipped: true
        },
        singleRun: true,
        browserConsoleLogOptions: {
            terminal: true,
            level: ""
        },
        customLaunchers: {
            ChromeDebugging: {
                base: 'Chrome',
                flags: ['--remote-debugging-port=9222'],
                debug: true
            },
            ChromeHeadlessCustom: {
                base: 'ChromeHeadless',
                flags: ['--no-sandbox', '--disable-translate', '--disable-extensions']
            }
        },
        autoWatch: false,
        browserDisconnectTolerance: 5,
        browserNoActivityTimeout: 60000,
        browserDisconnectTimeout: 30000,
        captureTimeout: 60000
    };

    if (argv.debug) {
        settings.preprocessors = {
            '**/*.html': ['ng-html2js']
        };
        settings.browsers = ['Chrome'];
        settings.singleRun = false;
    }

    if (argv.lr || argv.liveReload) {
        settings.singleRun = false;
    }

    if (argv.dots) {
        settings.reporters = settings.reporters.map(function(reporter) {
            return reporter === 'spec' ? 'dots' : reporter;
        });
    }

    if (argv.quickrun) {
        settings.specReporter.suppressPassed = true;
        settings.specReporter.suppressErrorSummary = true;
        settings.specReporter.suppressFailed = false;
    }

    if (argv.teamcity) {
        settings.reporters = ['teamcity'];
    }

    if(argv.coverage){
        settings.reporters = ['teamcity', 'coverage'];
    }
    
    config.set(settings);
};

function loadFiles(baseFolder, useTmp) {
    var currentPath = useTmp ? path.join(__dirname, baseFolder, 'tmp') : path.join(__dirname, baseFolder);

    var indexFiles = [];
    walk(currentPath, function(a) {
        indexFiles.push(a);
    });

    var files = [];    
    indexFiles.forEach(function(indexFile) {
        var $ = cheerio.load(require('fs').readFileSync(indexFile));
        $('script[src]').each(function() {
            var p;
            var src = $(this).attr('src');
            var nodeModuleIndex = src.indexOf('node_modules');
            if (nodeModuleIndex >= 0) {
                if (src.indexOf('..') >= 0) {
                    var actualPath = src.substring(nodeModuleIndex);
                    p = path.join(__dirname, actualPath);
                } else {
                    p = path.join(__dirname, src);
                }
            } else {
                p = path.join(__dirname, baseFolder, src);
                if (!fs.existsSync(p)) {
                    var folderDir = pathHelper.dirname(indexFile);
                    var folderName = folderDir.replace(currentPath, '');
                    p = path.join(__dirname, baseFolder, folderName, src);
                }
            }            
            files.push(p);
        });
    });

    var templateUrls = glob.sync(path.join(__dirname, 'client/condor/**/directives/**/*.html'), {
        dot: true
    });

    var specs = glob.sync(path.join(__dirname, 'client/signin/**/*.spec.js'), {
        dot: true
    }).concat(glob.sync(path.join(__dirname, 'client/condor/**/*.spec.js'), {
        dot: true
    }));

    var mocks = glob.sync(path.join(__dirname, 'client/condor/**/*.mock.js'), {
        dot: true
    });

    mocks.unshift(path.join(__dirname, 'client/condor/mocks/module.js'));
    
    files = files.concat([path.join(__dirname, 'node_modules/angular-mocks/angular-mocks.js')]);
    files.push(path.join(__dirname, 'client/downgrade.mock.provider.js'));
    files.push(path.join(__dirname, 'test.conf.js'));
    files = files.concat(mocks).concat(specs);
    files = files.concat(templateUrls);
   
    return files;
}

function walk(path, cb) {
    // exclude tmp/ng from testing
    if ((path.indexOf('tmp\\ng') === -1) && (path.indexOf('tmp\\signin') === -1)) {       
    var filesInDir = fs.readdirSync(path);

    filesInDir.forEach(function(a) {
        var p = pathHelper.join(path, a);
        if (fs.lstatSync(p).isDirectory()) {

            walk(p, cb);
        } else if (/index.html$/i.test(p)) {
            cb(p);
        }
    });
    }
}