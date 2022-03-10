'use strict';

var through = require('through2');
var service = require('../common/ng-service');

exports.getNg = getNg;
exports.convert = convert;

function convert(cwd, options) {
    return through.obj(function(file, enc, cb) {
        var html = file.contents.toString();
        var jsFiles = service.findNgJs(cwd, options);
        var scripts = service.buildScriptTags(cwd, jsFiles);
        var newHtml = service.replace(html, scripts);

        file.contents = new Buffer(newHtml);

        cb(null, file);
    });
}

function getNg(cwd, compress) {
    var jsFiles = service.findNgJs(cwd, null, true, compress);
    var includeStr = '';
    if (jsFiles) {
        for (var i = 0; i < jsFiles.length; i++) {
            includeStr += '<script src="ng/' + jsFiles[i] + '"></script>';
        }
    }
    return includeStr;
}