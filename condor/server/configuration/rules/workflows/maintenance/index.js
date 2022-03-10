'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../../../../utils');
var _ = require('underscore');

router.get('/api/configuration/rules/workflows/*/characteristics', function(req, res) {
    res.json({
        id: 111,
        criteriaName: 'Criteria 111',
        action: {
            key: 'AC',
            value: 'Acceptance',
            isValid: true
        },
        basis: {
            key: 'N',
            value: 'Non-Convention',
            isValid: true
        },
        caseCategory: {
            key: '3',
            value: '.BIZ',
            isValid: true
        },
        caseType: {
            key: 'A',
            value: 'Properties',
            isValid: true
        },
        dateOfLaw: {
            key: '1901-01-01T00:00:00',
            value: '01-Jan-1901',
            isValid: true
        },
        jurisdiction: {
            key: 'AT',
            value: 'Austria',
            isValid: true
        },
        office: {
            key: '10176',
            value: 'City Office',
            isValid: true
        },
        propertyType: {
            key: 'T',
            value: 'Trade Marks',
            isValid: true
        },
        subType: {
            key: '30',
            value: 'PCT Chapter 2',
            isValid: true
        },
        isLocalClient: true,
        isProtected: false,
        canEditProtected: true,
        isEditProtectionBlockedByParent: !(req.params.id % 2),
        isEditProtectionBlockedByDescendants: false
    });
});

router.get('/api/configuration/rules/workflows/*/events', function(req, res) {
    utils.readJson(path.join(__dirname, './eventControl.json'), function(data) {
        var total = data.length;
        var sortedPaginatedData = utils.sortAndPaginate(data, req.query.params);

        res.json({
            data: sortedPaginatedData,
            pagination: {
                total: total
            },
            ids: _.map(sortedPaginatedData, function(d) {
                return d.eventNo;
            })
        });
    });
});

router.get('/api/configuration/rules/workflows/*/entries', function(req, res) {
    utils.readJson(path.join(__dirname, './entryControl.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/configuration/rules/workflows/*/eventSearch', function(req, res) {
    res.json([{
        eventId: parseInt(req.query.eventId)
    }]);
});

router.get('/api/configuration/rules/workflows/*/entryEventSearch', function(req, res) {
    res.json([1, 14, 15]);
});

router.delete('/api/configuration/rules/workflows/*/events', function(req, res) {
    res.end();
});

var descendants = [{
    id: 12,
    description: 'criteria 1'
}, {
    id: 13,
    description: 'criteria 2'
}];

router.get('/api/configuration/rules/workflows/*/events/descendants', function(req, res) {
    res.json(descendants);
});

router.get('/api/configuration/rules/workflows/*/entries/descendants', function(req, res) {
    res.json(descendants);
});

router.get('/api/configuration/rules/workflows/*/entries/descendants/withInheritedEntryIds*', function(req, res) {
    res.json(descendants);
});

router.delete('/api/configuration/rules/workflows/*/entries', function(req, res) {
    res.end();
});

router.get('/api/configuration/rules/workflows/*/descendants', function(req, res) {
    res.json([{
        criteriaId: 12,
        criteriaDescription: 'criteria 1'
    }, {
        criteriaId: 13,
        criteriaDescription: 'criteria 2'
    }]);
});

router.get('/api/configuration/rules/workflows/*/events/usedByCases', function(req, res) {
    res.json([{
        eventId: 12,
        description: 'event 1'
    }, {
        eventId: 13,
        description: 'event 2'
    }]);
});

router.put('/api/configuration/rules/workflows/*/events/*', function(req, res) {
    res.json({
        eventNo: -13,
        description: 'Date of Entry',
        displaySequence: 0,
        eventCode: 'QEI',
        importance: 'Critical',
        maxCycles: 1
    });
});

router.put('/api/configuration/rules/workflows/*', function(req, res) {
    res.end();
});

router.delete('/api/configuration/rules/workflows/*', function(req, res) {
    res.end();
});

router.post('/api/configuration/rules/workflows/*/events/reorder', function(req, res) {
    res.end();
});

router.post('/api/configuration/rules/workflows/*/events/descendants/reorder', function(req, res) {
    res.end();
});

router.post('/api/configuration/rules/workflows/*/entries/reorder', function(req, res) {
    res.json({
        descendents: descendants
    });
});

router.post('/api/configuration/rules/workflows/*/entries/descendants/reorder', function(req, res) {
    res.end();
});

module.exports = router;
