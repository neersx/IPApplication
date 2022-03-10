'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../utils');
router.get('/api/twoFactorAuthPreference', function(req, res) {
    utils.readJson(path.join(__dirname, './two-factor-preference.json'), function(data) {
        res.json(data);
    });
});

router.post('/api/twoFactorAuthPreference/twoFactorAppKeyDelete', function(req, res) {
    res.json(true);
});


router.get('/api/twoFactorAuthPreference/twoFactorTempKey', function(req, res) {
    res.json('fakeKey');
});

router.post('/api/twoFactorAuthPreference/twoFactorTempKeyVerify', function(req, res) {
    utils.readJson(path.join(__dirname, './two-factor-auth-key-verify.json'), function(data) {
        res.json(data);
    });
});

router.put('/api/twoFactorAuthPreference', function(req, res) {
    res.json({
        Status: 1
    });
});

module.exports = router;