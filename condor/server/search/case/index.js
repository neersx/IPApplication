'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../../utils');

router.get('/api/search/case/view/:queryContextKey?', function(req, res) {
    res.json({
        hasOffices: true,
        programs: [{
            id: 'CASENTRY',
            isDefault: true
        }],
        queryContextKey: req.queryContextKey || 2
    })
});
router.post('/api/search/case/columns', function(req, res) {
    setTimeout(function() {

        utils.readJson(path.join(__dirname, './caseColumns.json'), function(data) {
            res.json(data);
        });
    }, 1000);
});

router.get('/api/search/case/casesearch/view/:queryContextKey', function(req, res) {
    res.json({
        hasOffices: true,
        programs: [{
            id: 'CASENTRY'
        }],
        queryContextKey: 2
    });
});

module.exports = router;