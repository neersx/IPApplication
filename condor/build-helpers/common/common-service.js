'use strict';

var fs = require('fs');
var pathHelper = require('path');

exports.buildScriptTags = buildScriptTags;
exports.walk = walk;

function buildScriptTags(basePath, files, basePrefix) {

    //var base = (isNg) ? 'tmp/' + pathHelper.basename(basePath) : pathHelper.basename(basePath);
    var base = pathHelper.basename(basePath);
    if (basePrefix) {
        base = basePrefix + base;
    }
    files = files.map(function(a) {
        var p = pathHelper.relative(basePath, a).replace(/\\/g, '/');

        return '<script src="' + base + '/' + p + '"></script>';
    });

    return files.join('\n');
}


function walk(path, cb, compress) {
    var config = readConfig(path);
    var files = fs.readdirSync(path);

    files = files.filter(function(a) {
        return !isForTesting(a);
    });

    files = reorder(path, files, config);
    files.forEach(function(a) {
        var p = pathHelper.join(path, a);
        if (fs.lstatSync(p).isDirectory()) {
            walk(p, cb, compress);
        } else if (compress ? /\.gz$/i.test(pathHelper.extname(a)) : /\.js$/i.test(pathHelper.extname(a))) {
            cb(p);
        }
    });
}

function reorder(path, files, config) {
    files = orderByDefault(path, files);
    if (config && config.length) {
        files = orderByConfig(files, config);
    }

    return files;
}

function orderByConfig(files, orders) {
    var middle = null;

    orders.forEach(function(a, i) {
        if (a === '*') {
            if (middle != null) {
                throw new Error('* can only be used once');
            }
            middle = i;
            return;
        }

        remove(files, a);
    });

    if (middle == null) {
        return orders;
    }

    return orders.slice(0, middle)
        .concat(files)
        .concat(orders.slice(middle + 1, orders.length));
}

function orderByDefault(path, files) {
    var base = pathHelper.basename(path);
    var i, name;

    // look for a file called 'module'
    for (i = 0; i < files.length; i++) {
        name = pathHelper.basename(files[i], '.js');
        if (name === 'module') {
            break;
        }
    }

    // look for a file with same module name
    if (i >= files.length) {
        for (i = 0; i < files.length; i++) {
            name = pathHelper.basename(files[i], '.js');
            if (name === base) {
                break;
            }
        }
    }

    if (i < files.length) {
        var item = files.splice(i, 1)[0];
        files.unshift(item);
    }

    return files;
}

function remove(array, item) {
    var index = array.indexOf(item);

    array.splice(index, 1);

    return array;
}

function readConfig(path) {
    var config = pathHelper.join(path, '.includejs');
    if (!fs.existsSync(config)) {
        return null;
    }

    var contents = fs.readFileSync(config, {
        encoding: 'utf-8'
    });
    var lines = contents.match(/[^\r\n]+/g);

    lines = lines.filter(function(a) {
        return /^\s*$/.test(a) === false;
    });

    return lines.length ? lines : null;
}

function isForTesting(file) {
    return /\.(spec|mock)\.js$/i.test(file);
}