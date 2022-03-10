'use strict';

var router = require('express').Router();
var fs = require('fs');

router.get('/api/casecomparison/inboxview', function(req, res) {
    return res.json({
        viewData: {
            canUpdateCase: true
        }
    });
});

router.get('/api/casecomparison/inbox/review', function(req, res) {
    return res.json({
        result: 'success'
    });
});

router.get('/api/casecomparison/duplicatesView/*/*', function(req, res) {
    return res.json({

        viewData: {
            canUpdateCase: true,
            duplicates: [{
                    type: 'case-comparison',
                    notificationId: 777,
                    dataSource: 'Innography',
                    title: 'Another case with same link',
                    appNum: 'A9934567',
                    caseRef: 'CasterlyRock',
                    caseId: -777,
                    date: '2013-12-18T11:51:39.7599042+11:00'
                },
                {
                    type: 'case-comparison',
                    notificationId: 888,
                    dataSource: 'Innography',
                    title: 'Example Duplicate Cases',
                    appNum: 'A234567',
                    caseRef: 'Winterfell',
                    caseId: -888,
                    date: '2013-12-18T11:51:39.7599042+11:00',
                    isReviewed: false
                }
            ]
        }
    });
});

router.post('/api/casecomparison/inbox/notifications', function(req, res) {
    return res.json({
        pageCount: 10,
        hasMore: true,
        dataSources: [{
            id: 'Epo',
            count: 20,
            dmsIntegrationEnabled: false
        }, {
            id: 'UsptoPrivatePair',
            count: 10,
            dmsIntegrationEnabled: false
        }, {
            id: 'UsptoTsdr',
            count: 30,
            dmsIntegrationEnabled: true
        }, {
            id: 'Innography',
            count: 3000,
            dmsIntegrationEnabled: false
        }],
        notifications: [{
                type: 'error',
                notificationId: 3,
                caseId: null,
                appNum: '19999999',
                caseRef: null,
                dataSource: 'UsptoPrivatePair',
                title: 'Error',
                body: [{
                    type: 'Error',
                    message: 'Error found in downloaded data. Sorry, the entered Application Number \"19999999\" is not available. The number may have been incorrectly typed, or assigned to an application that is not yet available for public inspection.\n\t\t',
                    exceptionType: 'Inprotech.Integration.UsptoDataExtraction.HandlerExpectationFailureException',
                    exceptionDetails: [{
                        type: 'Inprotech.Integration.UsptoDataExtraction.HandlerExpectationFailureException',
                        message: 'Error found in downloaded data. Sorry, the entered Application Number \"19999999\" is not available. The number may have been incorrectly typed, or assigned to an application that is not yet available for public inspection.\n\t\t',
                        details: '   at Inprotech.Integration.UsptoDataExtraction.Extractors.PairDataErrorResponseResponseInspector.EnsureValid(String pairData) in c:\\src\\newkaizen\\inprotechkaizen\\Inprotech.Integration.UsptoDataExtraction\\Extractors\\PairDataErrorResponseInspector.cs:line 35\r\n   at Inprotech.Integration.UsptoDataExtraction.Extractors.ApplicationDetailsExtractor.<Extract>d__0.MoveNext() in c:\\src\\newkaizen\\inprotechkaizen\\Inprotech.Integration.UsptoDataExtraction\\Extractors\\ApplicationDetailsExtractor.cs:line 53\r\n--- End of stack trace from previous location where exception was thrown ---\r\n   at System.Runtime.CompilerServices.TaskAwaiter.ThrowForNonSuccess(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult()\r\n   at Inprotech.Integration.UsptoDataExtraction.Activities.ApplicationDetails.<Download>d__0.MoveNext() in c:\\src\\newkaizen\\inprotechkaizen\\Inprotech.Integration.UsptoDataExtraction\\Activities\\ApplicationDetails.cs:line 25\r\n--- End of stack trace from previous location where exception was thrown ---\r\n   at System.Runtime.CompilerServices.TaskAwaiter.ThrowForNonSuccess(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter.GetResult()\r\n   at Dependable.Dispatcher.MethodBinder.<Run>d__0.MoveNext()\r\n--- End of stack trace from previous location where exception was thrown ---\r\n   at System.Runtime.CompilerServices.TaskAwaiter.ThrowForNonSuccess(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult()\r\n   at Dependable.Dispatcher.Dispatcher.<Run>d__b.MoveNext()'
                    }],
                    dispatchCycle: 0,
                    date: '2014-10-22T21:30:31.2618267+11:00'
                }, {
                    type: 'Error',
                    message: 'Error found in downloaded data. Sorry, the entered Application Number \"19999999\" is not available. The number may have been incorrectly typed, or assigned to an application that is not yet available for public inspection.\n\t\t',
                    exceptionType: 'Inprotech.Integration.UsptoDataExtraction.HandlerExpectationFailureException',
                    exceptionDetails: [{
                        type: 'Inprotech.Integration.UsptoDataExtraction.HandlerExpectationFailureException',
                        message: 'Error found in downloaded data. Sorry, the entered Application Number \"19999999\" is not available. The number may have been incorrectly typed, or assigned to an application that is not yet available for public inspection.\n\t\t',
                        details: '   at Inprotech.Integration.UsptoDataExtraction.Extractors.PairDataErrorResponseResponseInspector.EnsureValid(String pairData) in c:\\src\\newkaizen\\inprotechkaizen\\Inprotech.Integration.UsptoDataExtraction\\Extractors\\PairDataErrorResponseInspector.cs:line 35\r\n   at Inprotech.Integration.UsptoDataExtraction.Extractors.ApplicationDetailsExtractor.<Extract>d__0.MoveNext() in c:\\src\\newkaizen\\inprotechkaizen\\Inprotech.Integration.UsptoDataExtraction\\Extractors\\ApplicationDetailsExtractor.cs:line 53\r\n--- End of stack trace from previous location where exception was thrown ---\r\n   at System.Runtime.CompilerServices.TaskAwaiter.ThrowForNonSuccess(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult()\r\n   at Inprotech.Integration.UsptoDataExtraction.Activities.ApplicationDetails.<Download>d__0.MoveNext() in c:\\src\\newkaizen\\inprotechkaizen\\Inprotech.Integration.UsptoDataExtraction\\Activities\\ApplicationDetails.cs:line 25\r\n--- End of stack trace from previous location where exception was thrown ---\r\n   at System.Runtime.CompilerServices.TaskAwaiter.ThrowForNonSuccess(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter.GetResult()\r\n   at Dependable.Dispatcher.MethodBinder.<Run>d__0.MoveNext()\r\n--- End of stack trace from previous location where exception was thrown ---\r\n   at System.Runtime.CompilerServices.TaskAwaiter.ThrowForNonSuccess(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult()\r\n   at Dependable.Dispatcher.Dispatcher.<Run>d__b.MoveNext()'
                    }],
                    dispatchCycle: 1,
                    date: '2014-10-22T21:31:03.6461085+11:00'
                }],
                isReviewed: false,
                date: '2014-10-22T21:31:04.057'
            }, {
                type: 'case-comparison',
                notificationId: 666,
                dataSource: 'UsptoPrivatePair',
                title: 'Notification with mapping errors',
                appNum: 'PCT/US10/46075',
                caseId: -666,
                date: '2013-12-18T11:51:39.7599042+11:00',
                isReviewed: false
            }, {
                type: 'case-comparison',
                notificationId: 777,
                dataSource: 'Innography',
                title: 'Touch screen protector',
                appNum: '13160404',
                pubNum: 'US8044942B1',
                regNum: 'US8044942B1',
                caseRef: '12537',
                caseId: -777,
                date: '2013-12-18T11:51:39.7599042+11:00'
            },
            {
                type: 'case-comparison',
                notificationId: 888,
                dataSource: 'Innography',
                title: 'Example Duplicate Cases',
                appNum: 'A234567',
                caseRef: 'Winterfell',
                caseId: -888,
                date: '2013-12-18T11:51:39.7599042+11:00',
                isReviewed: false
            },
            {
                type: 'case-comparison',
                notificationId: 1,
                dataSource: 'UsptoTsdr',
                title: 'VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY LONG TITLE',
                appNum: '61389191',
                pubNum: '61389191',
                caseRef: '1234/a',
                caseId: -487,
                date: '2013-12-18T11:51:39.7599042+11:00'
            }, {
                type: 'case-comparison',
                notificationId: 1,
                dataSource: 'UsptoPrivatePair',
                title: 'MODULAR INTERLOCKING CONTAINERS WITH ENHANCED INTERLOCKING MECHANISMS',
                appNum: 'PCT/US10/46075',
                caseId: -505,
                date: '2013-12-18T11:51:39.7599042+11:00',
                isReviewed: true
            }, {
                type: 'case-comparison',
                notificationId: 1,
                dataSource: 'UsptoPrivatePair',
                title: 'TRIANGULAR MODULAR INTERLOCKING CONTAINERS WITH DUAL CONNECTION CHANNELS ',
                appNum: '29422262',
                regNum: 'reg29422262',
                date: '2013-12-18T11:51:39.7599042+11:00'
            }, {
                type: 'rejected',
                notificationId: 1,
                dataSource: 'Innography',
                title: 'The magic mushroom',
                appNum: '61389191',
                regNum: 'reg61389191',
                caseRef: '1234/d',
                caseId: -483,
                date: '2013-12-18T11:51:39.7599042+11:00',
                isReviewed: true
            }, {
                type: 'case-comparison',
                notificationId: 1,
                dataSource: 'UsptoPrivatePair',
                title: 'CYLINDRICAL MODULAR INTERLOCKING CONTAINER',
                appNum: '61389191',
                regNum: 'reg61389191',
                caseRef: '1234/d',
                caseId: -483,
                date: '2013-12-18T11:51:39.7599042+11:00',
                isReviewed: true
            }, {
                type: 'case-comparison',
                notificationId: 1,
                dataSource: 'UsptoPrivatePair',
                title: 'RECTANGULAR MODULAR INTERLOCKING CONTAINERS WITH DUAL CONNECTION CHANNELS ',
                appNum: '29422333',
                date: '2013-12-18T11:51:39.7599042+11:00'
            }, {
                type: 'case-comparison',
                notificationId: 1,
                dataSource: 'UsptoPrivatePair',
                title: 'HEXAGONICAL MODULAR INTERLOCKING CONTAINER',
                appNum: '61389455',
                caseRef: '1234/d',
                caseId: -483,
                date: '2013-12-18T11:51:39.7599042+11:00',
                isReviewed: true,
                timeStamp: '2013-12-18T11:50:39.7599042+11:00'
            }, {
                type: 'case-comparison',
                notificationId: 1,
                dataSource: 'UsptoPrivatePair',
                title: 'OCTAGONICAL MODULAR INTERLOCKING CONTAINER',
                appNum: '61389455',
                caseRef: '1234/d',
                caseId: -483,
                date: '2013-12-18T11:51:39.7599042+11:00',
                isReviewed: true
            }
        ]
    });
});

router.get('/api/casecomparison/inbox/search', function(req, res) {
    return res.json({
        dataSources: [{
            id: 'UsptoTsdr',
            count: 3
        }],
        notifications: [{
            type: 'case-comparison',
            notificationId: 1,
            dataSource: 'UsptoTsdr',
            title: 'VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY VERY LONG TITLE',
            appNum: '61389191',
            caseRef: '1234/a',
            caseId: -487,
            date: '2013-12-18T11:51:39.7599042+11:00'
        }],
        hasMore: true,
        since: '2013-12-18T11:51:39.7599042+11:00'
    });
});

router.get('/api/casecomparison/inbox/reject-case-match', function(req, res) {
    return res.json({});
});

router.get('/api/img*', function(req, res) {
    var stat = fs.statSync('./server/classic/caseComparison/sample-trademark.png');
    res.writeHead(200, {
        'Content-Type': 'image/png',
        'Content-Length': stat.size
    });
    fs.createReadStream('./server/classic/caseComparison/sample-trademark.png').pipe(res);
});

module.exports = router;