'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../utils');
var fs = require('fs');
var _ = require('underscore');

function getRandomIntInclusive(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

function resetTimeslot(callback) {

    utils.readJson(path.join(__dirname, '/rateGraphData.json'), function(data) {

        var now = new Date();
        var slot = new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours() - 12, 0, 0);
        callback(_.map(data, function(item) {
            slot = new Date(slot.getFullYear(), slot.getMonth(), slot.getDate(), slot.getHours() + 1, 0, 0);
            return {
                id: item.id,
                timeSlot: slot,
                enterQueue: item.enterQueue,
                exitQueue: item.exitQueue
            };
        }));
    });
}

router.get('/api/policing/dashboard/view', function(req, res) {
    resetTimeslot(function(rateGraphData) {
        utils.readJson(path.join(__dirname, '/viewdata.json'), function(data) {
            utils.readJson(path.join(__dirname, '/policingRequestlogs.json'), function(requestlogData) {
                res.json({
                    summary: data[getRandomIntInclusive(0, 2)].summary,
                    trend: {
                        historicalDataAvailable: true,
                        hasError: false,
                        items: rateGraphData
                    },
                    requests: requestlogData.slice(0, 5)
                });
            });
        });
    });
});

router.get('/api/policing/queue/view', function(req, res) {
    utils.readJson(path.join(__dirname, '/viewdata.json'), function(data) {
        res.json({
            canAdminister: true,
            canMaintainWorkflow: true,
            summary: data[getRandomIntInclusive(0, 2)]
        });
    });
});

router.get('/api/policing/dashboard/rategraph', function(req, res) {
    var fileStream = fs.createReadStream(path.join(__dirname, '/rateGraphData.json'));
    res.type('json');
    fileStream.pipe(res);
});

router.get('/api/policing/queue/errors/*', function(req, res) {
    utils.readJson(path.join(__dirname, '/policingItemErrors.json'), function(data) {
        var paged = utils.sortAndPaginate(data, req.query.params);
        res.json({
            data: paged,
            pagination: {
                total: data.length
            }
        });
    });
});

router.post('/api/policing/queue/admin/release', function(req, res) {
    res.json();
});

router.post('/api/policing/queue/admin/hold', function(req, res) {
    res.json();
});


router.post('/api/policing/queue/admin/delete', function(req, res) {
    res.json();
});

router.post('/api/policing/queue/admin/release', function(req, res) {
    res.json();
});

router.post('/api/policing/queue/admin/hold', function(req, res) {
    res.json();
});


router.post('/api/policing/queue/admin/delete', function(req, res) {
    res.json();
});

router.get('/api/policing/queue/filterData/status/*', function(req, res) {
    res.json([{
        code: 'waiting-to-start',
        description: 'waiting-to-start'

    }, {
        code: 'in-error',
        description: 'in-error'
    }, {
        code: 'on-hold',
        description: 'on-hold'
    }, {
        code: 'failed',
        description: 'failed'
    }, {
        code: 'in-progress',
        description: 'in-progress'
    }, {
        code: 'blocked',
        description: 'blocked'
    }]);
});

router.get('/api/policing/queue/filterData/user/*', function(req, res) {
    res.json([{
        code: '45',
        description: 'George Grey'

    }]);
});

router.get('/api/policing/queue/filterData/caseReference/*', function(req, res) {
    res.json([{
        code: '1234/A',
        description: '1234/A'

    }]);
});

router.get('/api/policing/queue/*', function(req, res) {
    var type = req.params['0'].toLowerCase();
    if (type === 'view') {
        return res.json({});
    }

    var filters = {
        'progressing': ['in-progress', 'waiting-to-start'],
        'requires-attention': ['failed', 'blocked', 'in-error'],
        'on-hold': ['on-hold']
    };

    utils.readJson(path.join(__dirname, '/viewdata.json'), function(data) {
        var summary = data[getRandomIntInclusive(0, 2)].summary;
        utils.readJson(path.join(__dirname, '/policingItems.json'), function(data) {
            data = type === 'all' ? data : data.filter(function(item) {
                return _.contains(filters[type], item.status);
            });

            var paged = utils.sortAndPaginate(data, req.query.params);

            res.json({
                items: {
                    data: paged,
                    pagination: {
                        total: data.length
                    }
                },
                summary: summary
            });
        });
    });
});

router.get('/api/policing/dashboard/permissions', function(req, res) {
    res.json({
        canAdminister: true,
        canViewOrMaintainRequests: true,
        canManageExchangeRequests: true
    });
});

router.get('/api/policing/requestlog/view', function(req, res) {
    res.json({
        canViewOrMaintainRequests: true,
        canMaintainWorkflow: true
    });
});

router.get('/api/policing/requestlog/recent', function(req, res) {
    utils.readJson(path.join(__dirname, '/policingRequestlogs.json'), function(requestlogData) {
        res.json({
            requests: requestlogData.slice(0, 5),
            canViewOrMaintainRequests: true
        });
    });
});

router.get('/api/policing/requestlog/errors/*', function(req, res) {
    utils.readJson(path.join(__dirname, '/requestLogErrorItems.json'), function(data) {
        var paged = utils.sortAndPaginate(data, req.query.params);
        res.json({
            data: paged,
            pagination: {
                total: data.length
            }
        });
    });
});

router.get('/api/policing/requestlog', function(req, res) {
    utils.readJson(path.join(__dirname, '/policingRequestlogs.json'), function(data) {
        var filtered = utils.filterGridResults(data, req.query.params);
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        res.json({
            data: filtered,
            pagination: {
                total: total
            }
        });
    });
});

router.get('/api/policing/requestlog/filterData/policingName*', function(req, res) {
    res.json([{
        code: 'Daily Policing',
        description: 'Daily Policing'
    }]);
});

router.get('/api/policing/requestlog/filterData/status*', function(req, res) {
    res.json([{
        code: 'error',
        description: 'Error'

    }, {
        code: 'completed',
        description: 'Completed'

    }, {
        code: 'inProgress',
        description: 'In Progress'

    }]);
});

router.get('/api/policing/requests/view', function(req, res) {
    res.json({
        requests: [{
            "requestId": 1,
            "title": "Daily Policing",
            "notes": "Police daily"
        }, {
            "requestId": 1,
            "title": "Daily Policing -5 days",
            "notes": "Police daily and looking back 5 days"
        }, {
            "requestId": 1,
            "title": "Recalculate Criteria",
            "notes": "Recalculate Criteria"
        }, {
            "requestId": 1,
            "title": "Recalculate Crit AU, P RC",
            "notes": "Recalculate Criteria for Australian Patents"
        }, {
            "requestId": 1,
            "title": "Testing",
            "notes": "Tests"
        }, {
            "requestId": 1,
            "title": "Staff Holidays",
            "notes": "Police items for people going on leave"
        }, {
            "requestId": 1,
            "title": "Recalc - after moving IPRules",
            "notes": "Recalculation after moving IP Rules"
        }, {
            "requestId": 1,
            "title": "Recalc - after moving IPRules (RN)",
            "notes": "Recalculation after moving IP Rules -- renewals"
        }],
        schedules: []
    });
});

router.get('/api/policing/errorlog/view', function(req, res) {
    res.json({
        permissions: {
            canAdminister: true,
            canMaintainWorkflow: true
        }
    });
});

router.get('/api/policing/errorlog', function(req, res) {
    utils.readJson(path.join(__dirname, '/policingErrorlogs.json'), function(data) {
        var filtered = utils.filterGridResults(data, req.query.params);
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        res.json({
            data: filtered,
            pagination: {
                total: total
            }
        });
    });
});

router.get('/api/policing/requests/*', function(req, res) {
    res.json({
        "requestId": 1,
        "title": "Daily Policing",
        "notes": "Police daily",
        "startDate": null,
        "endDate": null,
        "dateLetters": null,
        "dueDateOnly": false,
        "forDays": null,
        "options": {
            "reminders": true,
            "emailReminders": true,
            "documents": true,
            "update": false,
            "adhocReminders": false,
            "recalculateCriteria": false,
            "recalculateDueDates": false,
            "recalculateReminderDates": false,
            "recalculateEventDates": false
        },
        "attributes": {
            "ExcludeJurisdiction": false,
            "PropertyType": null,
            "ExcludeProperty": false,
            "caseReference": null,
            "caseType": null,
            "caseCategory": null,
            "subType": null,
            "office": null,
            "action": null,
            "excludeAction": null,
            "event": null,
            "dateOfLaw": null,
            "nameType": null,
            "name": null
        }
    });
});

router.post('/api/policing/requests', function(req, res) {
    res.json({
        status: 'success',
        requestId: 4,
        affectedCases: {
            isSupported: false
        }
    });
});

router.put('/api/policing/requests/*', function(req, res) {
    res.json({
        status: 'success',
        affectedCases: {
            isSupported: false
        }
    });
});

router.post('/api/policing/requests/delete', function(req, res) {
    res.json({
        status: 'success',
        requests: [{
            "requestId": 1,
            "title": "Daily Policing",
            "notes": "Police daily"
        }, {
            "requestId": 2,
            "title": "Daily Policing -5 days",
            "notes": "Police daily and looking back 5 days"
        }, {
            "requestId": 3,
            "title": "Recalculate Criteria",
            "notes": "Recalculate Criteria"
        }, {
            "requestId": 4,
            "title": "Recalculate Crit AU, P RC",
            "notes": "Recalculate Criteria for Australian Patents"
        }, {
            "requestId": 5,
            "title": "Testing",
            "notes": "Tess"
        }, {
            "requestId": 6,
            "title": "Staff Holidays",
            "notes": "Police items for people going on leave"
        }, {
            "requestId": 7,
            "title": "Recalc - after moving IPRules",
            "notes": "Recalculation after moving IP Rules"
        }]
    });
});


router.get('/api/policing/errorlog/view', function(req, res) {
    res.json({
        permissions: {
            canAdminister: true,
            canMaintainWorkflow: true
        }
    });
});

router.get('/api/policing/errorlog', function(req, res) {
    utils.readJson(path.join(__dirname, '/policingErrorlogs.json'), function(data) {
        var filtered = utils.filterGridResults(data, req.query.params);
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        res.json({
            data: filtered,
            pagination: {
                total: total
            }
        });
    });

});

router.get('/api/policing/errorlog/filterData/caseRef*', function(req, res) {
    res.json([{
        code: '1234/A',
        description: '1234/A'
    }]);
});

module.exports = router;
