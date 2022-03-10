'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../utils');
var _ = require('underscore');

router.get('/api/accounting/vat/obligations', function(req, res) {
    utils.readJson(path.join(__dirname, './vat-obligations.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/accounting/vat/vatlogs', function(req, res) {
    utils.readJson(path.join(__dirname, './vat-logs.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/accounting/vat/view', function(req, res) {
    res.json({
        entityNames: [{
            id: 1,
            displayName: "Mike Ross & Partners",
            taxCode: "688951659"
        }, {
            id: 2,
            displayName: "Pearson Specter & Litt",
            taxCode: "126705184"
        }, {
            id: 3,
            displayName: "The Corner Shop",
            taxCode: ""
        }, {
            id: 999,
            displayName: "Inventorz 'R Us",
            taxCode: "983475845897"
        }],
        authCode: "__theAuthCode__"
    });
});

router.get('/api/accounting/vat/authorise', function(req, res) {
    res.json({
        accessToken: '__theAccessToken__',
        refreshToken: '__theRefreshToken__',
        expiresIn: 14400,
        tokenType: 'bearer',
        loginUri: 'localhost:9100/#/accounting/vat',
        stateKey: new Date().getTime()
    });
});

router.get('/api/accounting/vat/vatdata', function(req, res) {
    setTimeout(function() {
        res.json({
            value: Number(Math.floor(Math.random() * Math.floor(500000)))
        });
    }, 500);
});

router.get('/api/accounting/vat/vatreturn', function(req, res) {
    var vatValues = _.times(9, function() {
        return Number(Math.floor(Math.random() * Math.floor(500000)));
    });
    if ((Math.floor(Math.random() * 10)) % 2 > 0) {
        res.json({
            vatResponse: {
                processingDate: new Date().toISOString(),
                paymentIndicator: 'BANK',
                formBundleNumber: Math.floor(Math.random() * Math.floor(500000)),
                chargeRefNumber: new Date().getTime()
            },
            vatReturnData: {
                status: 'Not Found',
                error: {
                    code: 'NOT_FOUND',
                    message: 'The remote endpoint has indicated that no associated data is found'
                }
            }
        });
    } else {
        res.json({
            vatResponse: {
                processingDate: new Date().toISOString(),
                paymentIndicator: 'BANK',
                formBundleNumber: Math.floor(Math.random() * Math.floor(500000)),
                chargeRefNumber: new Date().getTime()
            },
            vatReturnData: {
                status: 'ok',
                data: vatValues
            }
        });
    }
});

router.post('/api/accounting/vat/submit', function(req, res) {
    if ((Math.floor(Math.random() * 10)) % 2 > 0) {
        res.json({
            code: 'INVALID_REQUEST',
            message: 'Invalid request',
            errors: [{
                code: 'INVALID_MONETARY_AMOUNT',
                message: 'The value must be between -9999999999999 and 9999999999999',
                path: '/totalValueGoodsSuppliedExVAT'
            }, {
                code: 'INVALID_MONETARY_AMOUNT',
                message: 'The value must be between -9999999999999 and 9999999999999',
                path: '/totalAcquisitionsExVAT'
            }]
        });
    } else {
        res.json({
            processingDate: new Date().toISOString(),
            paymentIndicator: 'BANK',
            formBundleNumber: Math.floor(Math.random() * Math.floor(500000)),
            chargeRefNumber: new Date().getTime()
        });
    }
});

router.get('/api/accounting/vat/settings/hmrcHeaders', function(req, res) {
    utils.readJson(path.join(__dirname, './vat-hmrcheaders.json'), function(data) {
        res.json(data);
    });
});

module.exports = router;