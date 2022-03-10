'use strict';

var common = require('./common-service');

exports.buildScriptTags = buildScriptTags;
exports.replace = replace;
exports.findJs = findJs;

function replace(html, contents) {
    return html.replace(/<!--\s*include-js\s*-->/i, contents);
}

function buildScriptTags(basePath, files) {
    return common.buildScriptTags(basePath, files);
}

function findJs(path, options, compress) {
    var files = [];

    common.walk(path, function(a) {
        files.push(a);
    }, compress);

    if (options && options.filter) {
        files = files.filter(options.filter);
    }

    return files;
}