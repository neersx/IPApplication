'use strict';

var File = require('vinyl');
var fs = require('fs');
var cheerio = require('cheerio');
var path = require('path');
var util = require('gulp-util');
var findmin = require('../common/find-min');

module.exports = load;

function load(options) {
    var cwd = options.cwd || process.cwd();
    var html = fs.readFileSync(path.join(cwd, options.htmlFile));
    var onlyExternal = options.onlyExternalFiles || false;
    var $ = cheerio.load(html);

    var files = [];
    $('script').each(function() {
        var min = $(this).attr('data-min-src');
        var file = $(this).attr('src');
        var isExternalFile = $(this).attr('is-external');
        var combine = $(this).attr('data-concat') != 'false';
        var isBower = (file && file.indexOf('bower_components') >= 0) || (min && min.indexOf('bower_components') >= 0);

        if (file && combine && (!onlyExternal || (onlyExternal && isExternalFile))) {
            util.log('[' + (isBower ?
                'Bower' : 'NPM') + ']: ' + file);
            file = findmin(file, min);
            files.push(file);
        }
    });

    files = files.map(function(file) {
        var vf = new File({
            path: file.path
        });
        vf.isMinified = file.isMinified;

        vf.contents = fs.readFileSync(path.join(cwd, file.path));

        return vf;
    });

    var Readable = require('stream').Readable;
    var reader = new Readable({
        objectMode: true
    });

    reader._index = 0;
    reader._read = function() {
        if (this._index >= files.length) {
            this.push(null);
            return;
        }

        this.push(files[this._index++]);
    };

    return reader;
}