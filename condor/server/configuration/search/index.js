'use strict';

var router = require('express').Router();
var fs = require('fs');
var path = require('path');
var _ = require('underscore');
var utils = require('../../utils');

router.get('/api/configuration/search/view', function(req, res) {
    res.json({
        canUpdate: true
    });
});

router.get('/api/configuration/search', function(req, res, next) {
    fs.readFile(path.join(__dirname, '/searchResults.json'), function(err, str) {
        if (err) {
            return next(err);
        }

        var data = JSON.parse(str);
        var index = parseInt(Math.random() * data.length);
        var latency = parseInt(Math.random() * 500);
        var total = data.length - index;
        data = _.shuffle(data).slice(index, index + 20);

        var sort = req.query.sortBy;
        var dir = req.query.sortDir;

        data = sort ? _.sortBy(data, sort) : data;

        if (sort && dir && dir === 'desc') {
            data = data.reverse();
        }

        setTimeout(function() {
            res.json({
                data: data,
                pagination: {
                    total: total
                }
            });
        }, latency);
    });
});

router.get('/api/configuration/tags', function(req, res) {
    res.json([{
        "id": 7,
        "tagName": "Bill"
    }, {
        "id": 4,
        "tagName": "Example"
    }, {
        "id": 13,
        "tagName": "FILE"
    }, {
        "id": 8,
        "tagName": "Help"
    }, {
        "id": 1,
        "tagName": "needs-review"
    }, {
        "id": 5,
        "tagName": "new tag"
    }, {
        "id": 2,
        "tagName": "Not-in-use"
    }]);
});

router.post('/api/configuration/tags', function(req, res) {
    res.end();
});

router.put('/api/configuration/item', function(req, res) {
    res.json({});
});

router.get('/api/configuration/components', function(req, res) {
    utils.readJson(path.join(__dirname, '/components.json'), function(data) {
        var filtered = filterBySearchText(data, req.query.search, 'componentName');
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);

        setTimeout(function() {
            res.json({
                data: filtered,
                pagination: {
                    total: total
                }
            });
        }, parseInt(req.query.latency || 0));
    });
});

function filterBySearchText(all, searchText, field) {
    if (!searchText || searchText === '') {
        return all;
    }
    searchText = searchText.toUpperCase();

    return _.filter(all, function(item) {
        return item[field] && item[field].toUpperCase().indexOf(searchText) > -1 || item.value && item.value.toUpperCase().indexOf(searchText) > -1;
    });
}

module.exports = router;