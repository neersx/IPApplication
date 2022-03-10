'use strict';

var router = require('express').Router();
var fs = require('fs');
var path = require('path');
var _ = require('underscore');
var utils = require('../utils');

router.get('/api/dev/typeahead/multiselect', function(req, res, next) {
    fs.readFile(path.join(__dirname, '../configuration/components.json'), function(err, str) {
        if (err) {
            return next(err);
        }

        var data = JSON.parse(str);
        data = data.filter(function(item) {
            return item.componentName.toUpperCase().indexOf(req.query.q.toUpperCase()) !== -1 || item.id.toString().indexOf(req.query.q) !== -1;
        });

        setTimeout(function() {
            res.json(data);
        }, parseInt(req.query.latency || 0));
    });
});

router.get('/api/signout', function(req, res) {
    res.status(401);
    res.end();
});

router.post('/api/signin', function(req, res) {
    if (req.body.username === 'internal' && req.body.password === 'internal') {
        res.json({
            status: 'success'
        });
    } else {
        res.json({
            status: 'unauthorised'
        });
    }
});

router.post('/api/dev/typeahead/multiselect', function(req, res) {
    setTimeout(function() {
        res.end();
    }, parseInt(req.query.latency || 0));
});

router.get('/api/dev/grid/results', function(req, res, next) {
    loadGridData(function(err, str) {
        if (err) {
            return next(err);
        }

        if (req.query.params) {
            var all = utils.filterGridResultsOnCodeProperty(JSON.parse(str), req.query.params);
            var filtered = utils.sortAndPaginate(all, req.query.params);

            returnPaginatedResults(req, res, filtered, all.length);
        }
        else{
            res.json(_.take(JSON.parse(str), 5));            
        }
    });
});

router.get('/api/dev/grid/filtermetadata/:column', function(req, res) {
    setTimeout(function() {
        utils.readColumnData(path.join(__dirname, 'grid.json'), req.params.column, function(data) {
            res.json(data);
        });
    }, parseInt(req.query.latency || 0));
});

function returnPaginatedResults(req, res, data, total) {
    setTimeout(function() {
        res.json({
            data: data, 
            pagination: {
                total: total
            }
        });
    }, parseInt(req.query.latency || 0));
}

function loadGridData(cb) {
    var gridResultsPath = path.join(__dirname, 'grid.json');

    fs.readFile(gridResultsPath, function(err, str) {
        cb(err, str);
    });
}

router.get('/api/dev/barchart/results', function(req, res) {
    utils.readJson(path.join(__dirname, 'barchart.json'), function(data) {
        if (JSON.parse(req.query.params).page % 2 === 0) {
            setTimeout(function() {
                res.json(_.initial(data, 5));
            }, 5000);
        } else {
            res.json(_.last(data, 5));
        }
    });
});

module.exports = router;
