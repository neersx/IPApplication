'use strict';

function buildAvailableDocuments() {
    return [{
        mailRoomDate: '2012-06-23T00:00:00',
        code: 'ALW',
        description: 'Notice of Allowance',
        category: 'PROSECUTION',
        pageCount: 1,
        imported: true,
        status: 'Downloaded',
        eventUpdatedDescription: 'Notice of Allowance Received'
    }, {
        mailRoomDate: '2012-06-03T00:00:00',
        code: 'P.202.IN',
        description: 'Incoming ISA/202 - Notification of Receipt of Search Copy',
        category: 'PROSECUTION',
        pageCount: 2,
        imported: true,
        status: 'Downloaded',
        eventUpdatedDescription: 'Notification of Receipt Received',
        eventUpdatedCycle: 3
    }, {
        mailRoomDate: '2012-03-03T00:00:00',
        code: 'P.105',
        description: 'RO/105 - Notification of the IA Number and of the International Filing Date',
        category: 'PROSECUTION',
        pageCount: 4,
        imported: true,
        status: 'Downloaded'
    }, {
        mailRoomDate: '2010-02-13T00:00:00',
        code: 'P.102',
        description: 'RO/102 - Notification Concerning Payment of Prescribed Fees and Annex',
        category: 'PROSECUTION',
        pageCount: 5,
        status: 'Downloaded'
    }, {
        mailRoomDate: '2010-01-03T00:00:00',
        code: 'ABST',
        description: 'Abstract',
        category: 'PROSECUTION',
        pageCount: 1,
        imported: true,
        status: 'FailedToSendToDms'
    }, {
        mailRoomDate: '2009-07-23T00:00:00',
        code: 'P.202.IN',
        description: 'Incoming ISA/202 - Notification of Receipt of Search Copy',
        category: 'PROSECUTION',
        pageCount: 2,
        status: 'SendToDms',
        eventUpdatedDescription: 'Notification of Receipt Received',
        eventUpdatedCycle: 2

    }, {
        mailRoomDate: '2009-07-23T00:00:00',
        code: 'P.202.IN',
        description: 'Incoming ISA/202 - Notification of Receipt of Search Copy',
        category: 'PROSECUTION',
        pageCount: 2,
        status: 'SendingToDms',
        eventUpdatedDescription: 'Notification of Receipt Received',
        eventUpdatedCycle: 1
    }, {
        mailRoomDate: '2000-06-03T00:00:00',
        code: 'SPEC',
        description: 'Specification',
        category: 'PROSECUTION',
        pageCount: 1,
        status: 'SentToDms'
    }, {
        mailRoomDate: '2000-06-03T00:00:00',
        code: 'SPEC',
        description: 'Specification',
        category: 'PROSECUTION',
        pageCount: 1,
        status: 'FailedToSendToDms',
        errors: {
            'type': 'Error',
            'category': 'DmsIntegrationError',
            'activityType': 'Inprotech.IntegrationServer.PtoAccess.DmsIntegration.ISendDocumentToDms, Inprotech.IntegrationServer, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null',
            'method': 'SendToDms',
            'arguments': [13, 49],
            'message': 'failed',
            'data': {},
            'exceptionType': 'System.Exception',
            'exceptionDetails': [{
                'type': 'System.Exception',
                'message': 'failed',
                'details': '   at Inprotech.IntegrationServer.PtoAccess.DmsIntegration.SendDocumentToDms.<SendToDms>d__0.MoveNext() in c:\\0Source\\inprotechkaizen\\Inprotech.IntegrationServer\\PtoAccess\\DmsIntegration\\SendDocumentToDms.cs:line 50\r\n--- End of stack trace from previous location where exception was thrown ---\r\n   at System.Runtime.CompilerServices.TaskAwaiter.ThrowForNonSuccess(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter.GetResult()\r\n   at Dependable.Dispatcher.MethodBinder.<Run>d__0.MoveNext()\r\n--- End of stack trace from previous location where exception was thrown ---\r\n   at System.Runtime.CompilerServices.TaskAwaiter.ThrowForNonSuccess(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)\r\n   at System.Runtime.CompilerServices.TaskAwaiter`1.GetResult()\r\n   at Dependable.Dispatcher.Dispatcher.<Run>d__b.MoveNext()'
            }],
            'dispatchCycle': 0,
            'date': '2015-04-21T15:26:33.4815606+10:00'
        }
    }];
}

var router = require('express').Router();

router.get('/api/casecomparison/*/documents/', function(req, res) {
    return res.json(buildAvailableDocuments());
});

router.get('/api/casecomparison/downloaddocument/', function(req, res) {
    return res.json({
        PDF: 'Fake server can only return JSON. Just imagine this is the PDF you will download :)'
    });
});

module.exports = router;