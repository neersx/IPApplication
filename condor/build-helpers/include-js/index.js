'use strict';

var through = require('through2');
var fs = require('vinyl-fs');
var jsFiles = ['lib', 'app'];
var service = require('../common/js-service');

exports.convert = convert;
exports.src = loadJs;
exports.getJs = getJs;

function convert(cwd, options) {
    return through.obj(function(file, enc, cb) {
        var html = file.contents.toString();
        var jsFiles = service.findJs(cwd, options);
        var scripts = service.buildScriptTags(cwd, jsFiles);
        var newHtml = service.replace(html, scripts);

        file.contents = new Buffer(newHtml);

        cb(null, file);
    });
}

function loadJs(cwd, options) {
    var paths = service.findJs(cwd, options);
    return fs.src(paths, options);
}

function getJs(cwd, options, compress) {
    var files = [];
    var directoryFiles = service.findJs(cwd, options, compress);
    for (var i = 0; i < jsFiles.length; i++) {
        var a = undefined;
        for (var j = 0; j < directoryFiles.length; j++) {
            if (directoryFiles[j].includes(jsFiles[i])) {
                a = directoryFiles[j];
                var filePath = a.substr(a.lastIndexOf('\\') + 1);
                files.push(filePath);
            }
        }
    }

    var includeStr = '';
    if (files) {
        for (var k = 0; k < files.length; k++) {
            includeStr += '<script src="condor/' + files[k] + '"></script>';
        }
    }
    return includeStr;
}