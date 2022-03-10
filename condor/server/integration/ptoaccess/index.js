'use strict';

var router = require('express').Router();
var utils = require('../../utils');
var path = require('path');
var fs = require('fs');

router.get('/api/ptoaccess/newscheduleview', function(req, res) {
    var response = {
        viewData: {
            dataSources: [{
                id: 'UsptoPrivatePair',
                dmsIntegrationEnabled: true
            }, {
                id: 'UsptoTsdr',
                dmsIntegrationEnabled: false
            }, {
                id: 'Epo',
                dmsIntegrationEnabled: false
            }, {
                id: 'Innography',
                dmsIntegrationEnabled: false
            }]
        }
    };

    return res.json(utils.enrich(response));
});

router.post('/api/ptoaccess/newschedule/create', function(req, res) {
    res.json({
        result: 'success'
    });
});

router.get('/api/ptoaccess/scheduleview', function(req, res) {
    var allScheduleExecutions = JSON.parse(fs.readFileSync(path.join(__dirname, '/scheduleExecutions.json')));
    var recoverableCases = JSON.parse(fs.readFileSync(path.join(__dirname, '/recoverableCases.json')));
    var recoverableDocuments = JSON.parse(fs.readFileSync(path.join(__dirname, '/recoverableDocuments.json')));
    var response = {
        viewData: {
            schedule: {
                id: 1,
                name: 'Daily status check',
                runOnDays: 'Sun,Mon,Tue,Wed,Thu,Fri,Sat',
                dataSource: 'UsptoPrivatePair',
                downloadType: 'StatusChanges',
                startTime: '00:00:00',
                extension: {
                    CustomerNumbers: '1234,5678',
                    CertificateName: 'CPA Global'
                }
            },
            scheduleExecutions: allScheduleExecutions,
            recoverableCasesCount: recoverableCases.length,
            recoverableCases: recoverableCases,
            recoverableDocumentsCount: recoverableDocuments.length,
            recoverableDocuments: recoverableDocuments,
            recoveryScheduleStatus: 'Idle'
        }
    };

    res.json(utils.enrich(response));
});

router.get('/api/ptoaccess/scheduleExecutions/:scheduleId/failures', function(req, res) {
    var entity = JSON.parse(fs.readFileSync(path.join(__dirname, '/errordetails.json')));
    res.json(utils.enrich(entity));
});

router.get('/api/ptoaccess/schedules/:scheduleId/scheduleExecutions', function(req, res) {
    var status = req.query.status;
    var fileName = status === 'Failed' ? '/failedScheduleExecutions.json' : '/scheduleExecutions.json';

    var entity = JSON.parse(fs.readFileSync(path.join(__dirname, fileName)));
    res.json(utils.enrich(entity));
});

router.get('/api/ptoaccess/schedules/:scheduleId/scheduleExecutions/:scheduleExecutionId/raw-index', function(req, res) {
    res.end();
});

router.post('/api/ptoaccess/schedules/:scheduleId/recovery', function(req, res) {
    res.end();
});

router.get('/api/ptoaccess/failureSummaryView', function(req, res) {
    var schedules = JSON.parse(fs.readFileSync(path.join(__dirname, './failureSummaries.json')));
    res.json(utils.enrich(schedules));
});

router.post('/api/ptoaccess/failuresummary/retryall/:source', function(req, res) {
    res.end();
});

router.get('/api/ptoaccess/schedulesview', function(req, res) {
    var schedules = JSON.parse(fs.readFileSync(path.join(__dirname, './schedules.json')));
    res.json(schedules);
})

router.delete('/api/ptoaccess/schedules/:scheduleId', function(req, res) {
    res.json({
        result: 'success'
    });
})

router.post('/api/ptoaccess/schedules/runnow/:scheduleId', function(req, res) {
    res.json(utils.enrich({
        result: 'success'
    }));
});

router.post('/api/ptoaccess/schedules/stop/:scheduleId', function(req, res) {
    var schedules = JSON.parse(fs.readFileSync(path.join(__dirname, './schedules.json')));
    res.json({
        result: 'success',
        schedules: schedules.viewData.schedules
    });
});

module.exports = router;