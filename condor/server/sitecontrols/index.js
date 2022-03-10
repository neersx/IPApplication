'use strict';

var router = require('express').Router();
var fs = require('fs');
var path = require('path');
var _ = require('underscore');

router.get('/api/configuration/sitecontrols/view', function(req, res) {
    var fileStream = fs.createReadStream(path.join(__dirname, '/viewdata.json'));
    res.type('json');
    fileStream.pipe(res);
});

router.get('/api/configuration/sitecontrols', function(req, res, next) {
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

var nextIndex = 0;
router.get('/api/configuration/sitecontrols/:id', function(req, res) {
    var types = ['Decimal', 'Integer', 'String', 'Boolean'];
    var values = [2.71, 8, 'foobar', true];

    setTimeout(function() {
        res.json({
            id: req.params.id,
            name: 'sitecontrol ' + req.params.id,
            notes: 'sitecontrol ' + req.params.id + ' notes',
            dataType: types[nextIndex % types.length],
            value: values[nextIndex % values.length],
            initialValue: values[nextIndex % values.length],
            tags: [{
                'id': 1,
                'tagName': 'in use'
            }, {
                'id': 2,
                'tagName': 'uspto'
            }, {
                'id': 3,
                'tagName': 'DMS'
            }, {
                'id': 4,
                'tagName': 'mapping'
            }]
        });
    }, parseInt(Math.random() * 200));

    nextIndex++;
});

router.put('/api/configuration/sitecontrols', function(req, res) {
    setTimeout(function() {
        res.end();
    }, parseInt(Math.random() * 200));
});

module.exports = router;
