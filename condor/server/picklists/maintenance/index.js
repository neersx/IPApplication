'use strict';

var express = require('express');
var router = express.Router();


router.get('/api/picklists/events/:id', function(req, res) {
    res.json({
        data: {
            key: -1011785,
            code: '',
            notes: 'Acceptance 18 month deadline',
            description: '18M Acceptance Deadline',
            maxCycles: 1,
            clientImportance: 'Critical',
            internalImportance: 'Critical'
        }
    });
});

module.exports = router;
