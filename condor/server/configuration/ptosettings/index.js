'use strict';

var router = require('express').Router();

router.get('/api/configuration/ptosettings/epo', function(req, res) {
    res.json({
        result: {
            consumerKey: 'This is consumer key',
            privateKey: 'This is something secret, shhhhhhhh'
        }
    });
});

router.post('/api/configuration/ptosettings/epo', function(req, res) {
    res.json({
        result: { status: 'success' }
    });
});

router.put('/api/configuration/ptosettings/epo', function(req, res) {
    setTimeout(function() {
        res.json({
            result: { status: 'success' }
        });
    }, 500);
});

module.exports = router;