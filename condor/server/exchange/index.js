'use strict';

var router = require('express').Router();
var fs = require('fs');
var path = require('path');
var _ = require('underscore');

router.get('/api/exchange/requests/view', function(req, res) {
    var fileStream = fs.createReadStream(path.join(__dirname, '/viewdata.json'));
    res.type('json');
    fileStream.pipe(res);
});

router.get('/api/exchange/configuration/view', function(req, res) {
    var data = {
        settings: {
            server: 'https://EXCHANGE1234',
            domain: 'domain',
            userName: 'newStaff@thefirm.com',
            isServiceEnabled: false,
            password: null
        },
        passwordExists: true,
        hasValidSettings: true
    };
    res.json(data);
});

router.post('/api/exchange/configuration/save', function(req, res) {
    res.json({
        result: {
            status: 'success'
        }
    });
});

router.get('/api/exchange/configuration/status', function(req, res) {
    res.json({
        result: _.random(1) == 1
    });
});

module.exports = router;
