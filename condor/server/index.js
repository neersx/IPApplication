'use strict';

var express = require('express');
var app = express();
var _ = require('underscore');
var path = require('path');
var bodyParser = require('body-parser');

app.use(express.static('client'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));
app.disable('etag');

setupFakeApi();

var server = app.listen(process.env.PORT, function() {
    var host = server.address().address;
    var port = server.address().port;

    console.log('Listening at http://%s:%s', host, port);
});

server.once('error', function(err) {
    if (err.code === 'EADDRINUSE') {
        console.error('The port is already in use');
    } else {
        console.error(err.stack);
    }
});

function setupFakeApi() {
    var glob = require('glob');
    var fs = require('fs');
    var config = JSON.parse(fs.readFileSync(path.join(__dirname, '/config.json')));
    var includePatterns = config.includes;
    var excludePatterns = config.excludes;
    var files = [];
    var excludes = [];

    includePatterns.forEach(function(pattern) {
        files = files.concat(matches(pattern));
    });

    excludePatterns.forEach(function(pattern) {
        excludes = excludes.concat(matches(pattern));
    });

    files = _.difference(files, excludes);

    files.forEach(function(file) {
        var suffix = 'index.js';
        if (file.indexOf(suffix, file.length - suffix.length) !== -1) {
            console.log('Load module: ' + file);
            app.use(require('./' + file));
        }
    });

    function matches(pattern) {
        return glob.sync(pattern, {
            dot: true,
            cwd: __dirname
        });
    }
}
