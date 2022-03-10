'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../../../../utils');

router.get('/api/configuration/rules/workflows/:criteriaId/entrycontrol/:entryId', function(req, res) {
    if(req.params.entryId === "15"){
        res.json({
            isProtected: true,
            canEdit: false,
            isSeparator: true,
            criteriaId: req.params.criteriaId,
            entryId: req.params.entryId,
            description: '--------------------------------------------------------'
        });
        return;
    }
    res.json({
        isProtected: !(req.params.criteriaId % 2),
        canEdit: !(req.params.entryId % 2),
        criteriaId: req.params.criteriaId,
        entryId: req.params.entryId,
        description: 'Fake entry control description',
        userInstructions: 'Some fake user instructions',
        editBlockedByDescendents: true,
        showUserAccess: true,
        officialNumberType: {
            key: 'A',
            code: 'A',
            value: 'Application No.'
        },
        fileLocation: {
            key: 123456,
            value: 'B52'
        },
        policeImmediately: true,
        changeCaseStatus: {
            key: -216,
            value: 'Abandoned by client'
        },
        changeRenewalStatus: {
            key: -302,
            value: 'CPA to be notified'
        },
        displayEvent: {
            key: -22,
            value: 'Clients filing deadline'
        },
        hideEvent: {
            key: -13,
            value: 'Date of Entry'
        },
        dimEvent: {
            key: -1,
            value: 'Earliest Priority Date'
        },
        characteristics: {
            caseType: {
                key: 'A',
                value: 'Properties'
            },
            propertyType: {
                key: 'P',
                value: 'Patent'
            },
            jurisdiction: {
                key: 'AU',
                value: 'Australia'
            }
        }
    });
});

router.get('/api/configuration/rules/workflows/:criteriaId/entrycontrol/:entryId/details', function(req, res) {
    utils.readJson(path.join(__dirname, './details.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/configuration/rules/workflows/:criteriaId/entrycontrol/:entryId/documents', function(req, res) {
    res.json([{
        'isInherited': true,
        'document': {
            key: -15864,
            value: 'Petition for Extension of Time Under 37 CFR 1.136(b)'

        },
        'mustProduce': true
    }, {
        'isInherited': false,
        'document': {
            key: -15855,
            value: 'Fee Address Indication Form'
        },
        'mustProduce': false
    }]);
});

router.get('/api/configuration/rules/workflows/:criteriaId/entrycontrol/:entryId/steps', function(req, res) {
    utils.readJson(path.join(__dirname, './steps.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/configuration/rules/workflows/:criteriaId/entrycontrol/:entryId/useraccess', function(req, res) {
    res.json([{
        'isInherited': true,
        'id': 1,
        'value': 'internal'
    }, {
        'isInherited': false,
        'id': 2,
        'value': 'external'
    }]);
});

router.get('/api/configuration/roles/:roleId/users', function(req, res) {
    res.json(['abaston','ggrey','ccork']);
});

router.put('/api/configuration/rules/workflows/*/entrycontrol/*', function(req, res) {
    res.json({
        status: 'success'
    });
});

router.post('/api/configuration/rules/workflows/:criteriaId/entries?*', function(req, res) {
    res.json({
         entryNo: 9999,
         description: 'Dummy addition',
         displaySequence: 99,
         isSeparator: false
    });
});

module.exports = router;