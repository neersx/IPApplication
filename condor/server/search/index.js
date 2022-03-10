'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../utils');

router.get('/api/search/view/:queryContextKey', function(req, res) {
    res.json({
        isExternal: false,
        savedQueries: [],
        importanceOptions: [],
        canMaintainPublicSearch: true,
        canCreateSavedSearch: true,
        canUpdateSavedSearch: true,
        canDeleteSavedSearch: true,
        userHasDefaultPresentation: true
    });
});

router.get('/api/quicksearch/execute', function(req, res) {
    setTimeout(function() {
        utils.readJson(path.join(__dirname, './casesearch.json'), function(data) {
            res.json(data);
        });
    }, 1000);
});

router.get('/api/quicksearch/typeahead?:q', function(req, res) {
    if (req.query.q === '1234/A') {
        res.json([{
            id: 0,
            irn: "1234/A",
            matchedOn: null,
            sortOrder: 1,
            using: null
        }])
    } else {
        setTimeout(function() {
            utils.readJson(path.join(__dirname, './quicksearch.json'), function(data) {
                for (var i = 0; i < data.length; i++) {
                    data[i].irn = req.query.q + data[i].irn;
                }
                res.json(data);
            });
        }, 100);
    }
});

module.exports = router;