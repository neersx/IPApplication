'use strict';

var fs = require('fs');
var path = require('path');

module.exports = findmin;

function findmin(file, min) {
    if (min === 'true') {
        return {
            isMinified: true,
            path: file
        };
    } else if (min === 'false') {
        return {
            isMinified: false,
            path: file
        };
    } else if (min) {
        return {
            isMinified: true,
            path: min
        };
    }

    if (/[.-]min\./i.test(file)) {
        return {
            isMinified: true,
            path: file
        };
    }

    var possibles = iteratePossibleMinFiles(file);
    for (var i = 0; i < possibles.length; i++) {
        var p = possibles[i];
        if (fs.existsSync(p)) {
            return {
                isMinified: true,
                path: p
            };
        }
    }

    return {
        isMinified: false,
        path: file
    };
}

function iteratePossibleMinFiles(originalFile) {
    var pathWithoutExtension = path.join(path.dirname(originalFile), path.basename(originalFile, '.js'));
    return [
        pathWithoutExtension + '.min.js',
        pathWithoutExtension + '-min.js'
    ];
}