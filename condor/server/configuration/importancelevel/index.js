'use strict';

var router = require('express').Router();
var fs = require('fs');
var path = require('path');

router.get('/api/configuration/importancelevel/search', function(req, res) {
    var fileStream = fs.createReadStream(path.join(__dirname, '/searchResults.json'));
    res.type('json');
    fileStream.pipe(res);
});

router.get('/api/configuration/importancelevel/viewdata', function(req, res) {
    var fileStream = fs.createReadStream(path.join(__dirname, '/viewData.json'));
    res.type('json');
    fileStream.pipe(res);
});

module.exports = router;