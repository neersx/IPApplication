'use strict';

var router = require('express').Router();

router.get('/api/configuration/rules/workflows/inheritance*', function(req, res) {
    res.json({
        trees: [{
            id: 10004,
            name: 'TM Default & Overview Action (7)',
            isProtected: true,
            hasProtectedChildren: true,
            items: [{
                id: 15370,
                name: 'Greece Overview Action (1)',
                isProtected: true,
                isInSearch: true,
                hasProtectedChildren: false,
                items: [{
                    id: 15371,
                    name: 'TM Libya Overview Action',
                    isProtected: false,
                    hasProtectedChildren: true
                }]
            }, {
                id: 13456,
                name: 'TM Madrid Agreement Designate Overview Action (1)',
                isProtected: false,
                items: [{
                    id: 10494,
                    name: 'TM ARIPO Designate Overview Action',
                    hasProtectedChildren: false,
                    isProtected: false
                }]
            }, {
                id: 12352,
                name: 'TM Madrid Protocol Designated Overview Action (1)',
                isProtected: true,                
                isInSearch: true,
                hasProtectedChildren: true,
                items: [{
                    id: 34522,
                    name: 'TH Greece Madrid Protocol Designate Overview',
                    hasProtectedChildren: false,
                    isProtected: true
                }]
            }, {
                id: 38255,
                name: 'TM Philippines Overview Action',
                isProtected: true,
                hasProtectedChildren: false
            }]
        }, {
            id: 10005,
            name: 'TM Default Overview Action (7)',
            isProtected: true,
            hasProtectedChildren: true,
            items: [{
                id: 15371,
                name: 'Greece Overview Action (1)',
                isProtected: false,
                isInSearch: true,
                hasProtectedChildren: true,
                items: [{
                    id: 15372,
                    name: 'TM Libya Overview Action',
                    isProtected: true,
                    isFirstFromSearch: true
                }]
            }, {
                id: 13457,
                name: 'TM Madrid Agreement Designate Overview Action (1)',
                isProtected: false,
                hasProtectedChildren: true,
                items: [{
                    id: 10495,
                    name: 'TM ARIPO Designate Overview Action',
                    isProtected: true
                }]
            }, {
                id: 12353,
                name: 'TM Madrid Protocol Designated Overview Action (1)',
                isProtected: true,
                isInSearch: true,
                items: [{
                    id: 34523,
                    name: 'TH Greece Madrid Protocol Designate Overview',
                    isProtected: false
                }]
            }, {
                id: 38256,
                name: 'TM Philippines Overview Action',
                isProtected: true
            }]
        }],
        totalCount: 20,
        canEditProtected: true
    });
});

router.get('/api/configuration/rules/workflows/:childCriteriaId/usedByCase', function(req, res) {
    res.json(false);
});

router.delete('/api/configuration/rules/workflows/:childCriteriaId/inheritance', function(req, res) {
    res.end();
});

router.put('/api/configuration/rules/workflows/:childCriteriaId/inheritance', function(req, res) {
    res.end();
});

module.exports = router;
