'use strict';

var express = require('express');
var router = express.Router();

function instructionTypeData() {
    return {
        characteristics: [{
            id: '6',
            description: 'Auto req normal exam immediately when lodged'
        }, {
            id: '7',
            description: 'Auto req normal exam immediately dirn recvd'
        }, {
            id: '8',
            description: 'Auto req normal exam just before deadline'
        }, {
            id: '9',
            description: 'Req normal exam after dirn only with instructions'
        }, {
            id: '10',
            description: 'Send reminders about examination deadline'
        }],

        instructions: [{
            id: 10,
            description: 'Auto req normal exam after filing appln',
            characteristics: [{
                id: '6',
                selected: false
            }, {
                id: '7',
                selected: false
            }, {
                id: '8',
                selected: true
            }, {
                id: '9',
                selected: true
            }, {
                id: '10',
                selected: true
            }]
        }, {
            id: 11,
            description: 'Auto req normal exam after direction recvd',
            characteristics: [{
                id: '6',
                selected: true
            }, {
                id: '7',
                selected: true
            }, {
                id: '8',
                selected: false
            }, {
                id: '9',
                selected: false
            }, {
                id: '10',
                selected: false
            }]
        }, {
            id: 12,
            description: 'Request exam only on instructions',
            characteristics: [{
                id: '6',
                selected: false
            }, {
                id: '7',
                selected: false
            }, {
                id: '8',
                selected: false
            }, {
                id: '9',
                selected: false
            }, {
                id: '10',
                selected: false
            }]
        }, {
            id: 13,
            description: 'Auto req norm exam after dirn just < deadline',
            characteristics: [{
                id: '6',
                selected: true
            }, {
                id: '7',
                selected: true
            }, {
                id: '8',
                selected: true
            }, {
                id: '9',
                selected: true
            }, {
                id: '10',
                selected: true
            }]
        }, {
            id: 14,
            description: 'Auto req norm exam after dirn just < dl no rems',
            characteristics: [{
                id: '6',
                selected: false
            }, {
                id: '7',
                selected: false
            }, {
                id: '8',
                selected: false
            }, {
                id: '9',
                selected: false
            }, {
                id: '10',
                selected: false
            }]
        }]
    };
}

router.get('/api/configuration/instructionTypeDetails/:id', function(req, res) {
    res.json(instructionTypeData());
});

router.post('/api/configuration/instructionTypeDetails/save', function(req, res) {
    res.json(instructionTypeData());
});

module.exports = router;
