'use strict';

var express = require('express');
var _ = require('underscore');
var router = express.Router();

function instructionsByType(filterType) {
    var all = [{
        id: 10,
        typeId: '1',
        description: 'Auto req normal exam after filing appln'
    }, {
        id: 11,
        typeId: '1',
        description: 'Auto req normal exam after direction recvd'
    }, {
        id: 12,
        typeId: '1',
        description: 'Request exam only on instructions'
    }, {
        id: 13,
        typeId: '1',
        description: 'Auto req norm exam after dirn just < deadline'
    }, {
        id: 14,
        typeId: '1',
        description: 'Auto req norm exam after dirn just < dl no rems'
    }, {
        id: 20,
        typeId: '3',
        description: 'No reminders'
    }, {
        id: 21,
        typeId: '3',
        description: 'First reminder only'
    }, {
        id: 22,
        typeId: '3',
        description: 'Final reminders only'
    }, {
        id: 23,
        typeId: '3',
        description: 'All reminders'
    }, {
        id: 24,
        typeId: '3',
        description: 'Send debit note in advance in place of rems'
    }, {
        id: 25,
        typeId: '3',
        description: 'Second reminder only'
    }, {
        id: 29,
        typeId: '4',
        description: 'CPA renews via us - automatically'
    }, {
        id: 30,
        typeId: '4',
        description: 'Renew only after instruction'
    }, {
        id: 31,
        typeId: '4',
        description: 'Auto renew just before deadline'
    }, {
        id: 34,
        typeId: '4',
        description: 'Renewal handled elsewhere'
    }, {
        id: 38,
        typeId: '4',
        description: 'CPA - Client renews directly'
    }, {
        id: 39,
        typeId: '4',
        description: 'CPA renews via us - on instructions'
    }, {
        id: 40,
        typeId: '2',
        description: 'Auto file application immediately'
    }, {
        id: 41,
        typeId: '2',
        description: 'File application only on instructions'
    }, {
        id: 42,
        typeId: '2',
        description: 'Auto file application just before deadline'
    }];

    if (!filterType) {
        return all;
    }

    return _.filter(all, function(item) {
        return item.typeId === filterType;
    });
}

router.get('/api/instructions', function(req, res) {
    res.json(instructionsByType(req.query.typeId));
});

module.exports = router;
