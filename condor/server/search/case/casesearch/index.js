'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../../../utils');

router.get('/api/search/case/casesearch/view', function(req, res) {
    res.json({ hasOffices: true })
});

router.post('/api/search/case', function(req, res) {
    setTimeout(function() {
        utils.readJson(path.join(__dirname, './../../casesearch.json'), function(data) {
            res.json(data);
        });
    }, 1000);
});

module.exports = router;