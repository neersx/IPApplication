'use strict';

var path = require('path');
var router = require('express').Router();

router.put('/api/ip-platform/file/view-filing-instruction', function(req, res) {
    var enrich = function(obj) {
        return {
            result: obj
        };
    }

    if (req.query.caseKey === '-659') {
        res.json(enrich({
            errorDescription: 'Unable to find the corresponding case in FILE.'
        }));
    } else {
        res.json(enrich({
            progressUri: 'http://localhost:9001/api/ip-platform/file/fake-file-instruct-app'
        }));
    }
});

router.get('/api/ip-platform/file/fake-file-instruct-app', function(req, res) {
    res.sendFile(path.join(__dirname, './file-instruct.html'))
});

module.exports = router;