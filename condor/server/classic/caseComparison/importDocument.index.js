'use strict';

function buildDocumentToImport() {
    return {
        caseId: '12',
        documentId: 123,
        caseRef: 'PCT/US10/46075',
        title: 'MODULAR INTERLOCKING THING',
        activityDate: '2001-11-15T00:00:00',
        attachmentName: 'Incoming ISA/202 - Notification of Receipt of Search Copy',
        occurredEvents: [{
                description: 'Filing Receipt Received',
                eventId: 4,
                cycle: 1
            }, {
                description: 'Application Filing Date',
                eventId: -4,
                cycle: 1
            },
            {
                description: 'Application Filing Date1',
                eventId: -45,
                cycle: 1
            }
        ],
        activityTypes: [{
            description: 'Correspondence',
            id: 5802
        }, {
            description: 'Electronic Mail',
            id: 5805
        }],
        categories: [{
            description: 'General',
            id: 10280
        }, {
            description: 'Instruction',
            id: 10281
        }],
        attachmentTypes: [{
            description: 'Letter Relating to the Search and Examination Procedure',
            id: 119
        }, {
            description: 'Reply to Examination Report',
            id: 112
        }]
    };
}

var router = require('express').Router();

router.get('/api/casecomparison/importDocument/*/*', function(req, res) {
    return res.json(buildDocumentToImport());
});

router.post('/api/casecomparison/importDocument/save', function(req, res) {
    return res.json({
        result: {
            result: 'success'
        }
    });
});

module.exports = router;