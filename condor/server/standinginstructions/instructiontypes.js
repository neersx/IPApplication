'use strict';

var express = require('express');
var _ = require('underscore');
var router = express.Router();

function filterBySearchText(all, searchText) {
    if (!searchText || searchText === '') {
        return all;
    }

    return _.filter(all, function(item) {
        return item.value && item.value.indexOf(searchText) > -1;
    });
}

router.get('/api/instructiontypes', function(req, res) {
    var all = [{
        key: '1',
        code: 'E',
        value: 'Examination',
        recordedAgainst: 'Instructor'
    }, {
        key: '2',
        code: 'L',
        value: 'Lodging',
        recordedAgainst: 'Instructor'
    }, {
        key: '3',
        code: 'M',
        value: 'Renewal Reminder',
        recordedAgainst: 'Renewal Instructor',
        restrictedBy: 'Owner'
    }, {
        key: '4',
        code: 'R',
        value: 'Renewal',
        recordedAgainst: 'Renewal Instructor'
    }];

    res.json(filterBySearchText(all, req.query.search));
});

module.exports = router;
