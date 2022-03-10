'use strict';

var router = require('express').Router();

router.get('/api/externalApplication/externalApplicationTokenView', function(req, res) {
    res.json({
        viewData: {
            externalApps: [{
                id: '1',
                name: 'Trinogy',
                code: 'Trinogy',
                token: 'AB121',
                createdOn: '2013-12-18T11:51:39.7599042+11:00',
                createdBy: '-487',
                isActive: true,
                expiryDate: null
            }, {
                id: '2',
                name: 'Third Party System',
                code: 'TPS',
                token: 'DS121',
                createdOn: '2013-12-18T11:51:39.7599042+11:00',
                createdBy: '-487',
                isActive: true,
                expiryDate: null
            }, {
                id: '3',
                name: 'New System',
                code: 'NPS',
                token: null,
                createdOn: null,
                createdBy: null,
                isActive: false,
                expiryDate: null
            }]
        }
    });
});

router.post('/api/externalapplication/externalapplicationtoken/generatetoken*', function(req, res) {
    res.json({
        viewData: {
            result: 'success',
            token: '2345',
            expiryDate: null
        }
    });
});

router.get('/api/externalapplication/externalapplicationtokeneditview*', function(req, res) {
    res.json({
        result: {
            viewData: {
                id: '1',
                name: 'Trinogy',
                code: 'Trinogy',
                token: 'AB121',
                isActive: true,
                expiryDate: '18-Dec-2015',
                source: 'xml'
            }
        }
    });
});


router.get('/api/externalapplication/externalapplicationtoken/generatetoken', function(req, res) {
    res.json({
        result: {
            viewData: {
                result: 'success',
                token: '2345'
            }
        }
    });
});


router.post('/api/externalapplication/externalapplicationtoken/save', function(req, res) {
    res.json({
        viewData: {
            result: 'success'
        }
    });
});

module.exports = router;