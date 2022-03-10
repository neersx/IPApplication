'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../utils');
var _ = require('underscore');

router.get('/api/names/restrictions', function(req, res) {
    utils.readJson(path.join(__dirname, './name-restrictions.json'), function(data) {
        var ids = _.map(req.query.ids.split(','), function(i) { return parseInt(i); });
        var restricted = _.filter(data, function(i) {
            return _.contains(ids, i.id);
        });

        var unknown = _.reject(ids, function(i) {
            return _.find(restricted, function(j) {
                return i === j.id;
            })
        }).map(function(r) {
            return { id: r };
        });

        res.json(restricted.concat(unknown));
    });
});


module.exports = router;