'use strict';

var fs = require('fs');
var path = require('path');
var router = require('express').Router();

router.get('/api/recentCases', function(req, res) {
    var all = JSON.parse(fs.readFileSync(path.join(__dirname, '/recentCases.json')));
    res.json(all);
});

router.get('/api/portal/help', function(req, res) {
    var data = JSON.parse(fs.readFileSync(path.join(__dirname, '/help.json')));
    res.json(data);
});

router.get('/api/portal/links', function(req, res) {
    var data = JSON.parse(fs.readFileSync(path.join(__dirname, '/quick-links.json')));
    res.json(data);
});

module.exports = router;