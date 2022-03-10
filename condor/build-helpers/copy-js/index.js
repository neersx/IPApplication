'use strict';

var through = require('through2');
var cheerio = require('cheerio');
var util = require('gulp-util');
var fs = require('fs');
var path = require('path');
var findmin = require('../common/find-min');
var service = require('../common/js-service');

module.exports = copy;

function copy(dest) {
    return through.obj(function(file, encoding, cb) {
        var html = file.contents.toString();
        var $ = cheerio.load(html);
        var error = null;
        var files = [];        

        $('script[data-concat="false"]').each(function() {
            var isExternal = $(this).attr('data-external');
            if (isExternal === 'true') {
                util.log('[Copying File to Dist]: Skipping External Script- ' + $(this).attr('src'));
                return;
            }

            var min = $(this).attr('data-min-src');
            var filePath = $(this).attr('src');

            if (filePath) {
                filePath = findmin(filePath, min).path;
                util.log('[Copying File to Dist]: ' + filePath);

                var fileName = path.basename(filePath);
                var target = path.join(dest, fileName);

                var read = fs.createReadStream(filePath);
                var write=fs.createWriteStream(target);
                read.pipe(write);
                
                $(this).remove();
                files.push(target);
            }
        });
        if (files.length > 0) {
            var scripts = service.buildScriptTags(dest, files);
            $(scripts).insertBefore($("script").last());
            file.contents = new Buffer($.html());
        }

        cb(error, file);
    });
}