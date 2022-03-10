'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../../../utils');
var _ = require('underscore');

router.get('/api/configuration/system/mui/view', function(req, res) {
    /* supported languages are derived from user code of table type 47 */
    utils.readJson(path.join(__dirname, './supportLanguages.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/configuration/system/mui/search', function(req, res) {
    utils.readJson(path.join(__dirname, './translationExamples_de.json'), function(data) {

        var filtered = search(data, req.query.q);
        var latency = parseInt(Math.random() * 500);

        filtered = utils.filterGridResults(filtered, req.query.params);

        var total = filtered.length;

        filtered = utils.sortAndPaginate(filtered, req.query.params);

        setTimeout(function() {
            res.json({
                data: filtered,
                pagination: {
                    total: total
                }
            });
        }, latency);
    });
});

router.put('/api/configuration/system/mui', function(req, res) {
    res.json({
        
    });
});

function search(data, criteria) {
    var parsed = JSON.parse(criteria || {});

    var r = data;
    if (parsed.isRequiredTranslationsOnly) {
        r = _.filter(r, function(item) {
            return !item.translation;
        });
    }

    if (parsed.text !== '') {
        var searchText = parsed.text.toLowerCase();

        r = _.filter(r, function(item) {
            return (item.area || '').toLowerCase().indexOf(searchText) > -1 ||
                (item.original || '').toLowerCase().indexOf(searchText) > -1 ||
                (item.key || '').toLowerCase().indexOf(searchText) > -1 ||
                (item.translation || '').toLowerCase().indexOf(searchText) > -1;
        });
    }
    return r;
}

module.exports = router;
