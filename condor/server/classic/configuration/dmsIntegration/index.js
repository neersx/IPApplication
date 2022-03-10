'use strict';

var router = require('express').Router();
module.exports = router;

router.get('/api/configuration/DMSIntegration/databases', function (req, res) {
    res.json({
        pagination: {
            total: 3
        },
        total: 3,
        data: [
            {
                databaseId: 0,
                database: 'database1',
                server: 'server1',
                integrationType: 0,
                loginType: 1,
                customerId: 1
            },
            {
                databaseId: 1,
                database: 'database2',
                server: 'server2',
                integrationType: 2,
                loginType: 1,
                customerId: null
            },
            {
                databaseId: 2,
                database: 'database3',
                server: 'server3',
                integrationType: 2,
                loginType: 3,
                password: '*****',
                customerId: null
            }
        ]
    });
});

router.get('/api/configuration/DMSIntegration/settingsView', function (req, res) {
    res.json({
        viewData: [{
            dataSource: 'UsptoPrivatePair',
            isEnabled: false,
            documents: 5,
            location: '',
            job: {}
        }, {
            dataSource: 'UsptoPrivatePair',
            isEnabled: true,
            documents: 0,
            location: 'c:\\dms_file_location\\uspto\\pair',
            job: {
                jobExecutionId: 1,
                status: 'Idle',
                sentDocuments: 5,
                totalDocuments: 10,
                acknowledged: false
            }
        }, {
            dataSource: 'UsptoTsdr',
            isEnabled: true,
            documents: 5,
            location: 'c:\\dms_file_location\\uspto\\tsdr',
            job: {
                jobExecutionId: 2,
                status: 'Failed',
                sentDocuments: 5,
                totalDocuments: 10,
                acknowledged: false
            }
        }, {
            dataSource: 'UsptoTsdr',
            isEnabled: true,
            documents: 5,
            location: 'c:\\dms_file_location\\uspto\\tsdr',
            job: {
                jobExecutionId: 3,
                status: 'Completed',
                sentDocuments: 5,
                totalDocuments: 10,
                acknowledged: false
            }
        }]
    });
});

router.post('/api/dms/send/*', function (req, res) {
    res.json({
        isActive: true,
        jobExecution: {
            status: 'Started',
            state: null,
            hasErrors: null
        }
    });
});

router.put('/api/configuration/DMSIntegration/settings', function (req, res) {
    res.json({});
});