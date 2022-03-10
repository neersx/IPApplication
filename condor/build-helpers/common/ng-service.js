'use strict';

var common = require('./common-service');
var ngFiles = ['runtime', 'polyfills', 'styles', 'vendor', 'main'];

exports.replace = replace;
exports.buildScriptTags = buildScriptTags;
exports.findNgJs = findNgJs;


function replace(html, contents) {
    return html.replace(/<!--\s*include-ng-js\s*-->/i, contents);
}

function buildScriptTags(basePath, files) {
    return common.buildScriptTags(basePath, files, 'tmp/');
}

function findNgJs(path, options, isProd, compress) {
    var files = [];
    var directoryFiles = [];
    common.walk(path, function(file) {
        directoryFiles.push(file);
    }, compress);

    for (var i = 0; i < ngFiles.length; i++) {
        var a = undefined;
        for (var j = 0; j < directoryFiles.length; j++) {
            if (directoryFiles[j].includes(ngFiles[i])) {
                a = directoryFiles[j];
                var filePath = isProd ? a.substr(a.lastIndexOf('\\') + 1) : a;
                files.push(filePath);
            }
        }
    }

    if (options && options.filter) {
        files = files.filter(options.filter);
    }

    return files;
}