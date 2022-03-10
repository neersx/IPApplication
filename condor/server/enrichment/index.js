'use strict';

var fs = require('fs');
var express = require('express');
var router = express.Router();
var path = require('path');

router.get('/api/enrichment', function(req, res) {
    var fileStream = fs.createReadStream(path.join(__dirname, '/data.json'));
    res.type('json');
    fileStream.pipe(res);
});

module.exports = router;
