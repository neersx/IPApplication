'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../../utils');

var nameIdentity = 1;

function buildBatchSummaryResponse() {
    return {
        data: [{
            id: 1,
            status: 'Processed',
            result: 'Result',
            caseReference: '1234933/AU',
            caseReferenceUrl: 'default.aspx?casekey=1234933/AU',
            issues: ['Missing Name Details', 'Official Numbers missing'],
            propertyType: 'Trade Mark',
            country: 'Australia',
            officialNumber: '9239023-AU',
            caseTitle: 'Big Brown Baby Blubber Bubble Blower Box.'
        }, {
            id: 2,
            status: 'Processed',
            result: 'Result 1',
            caseReference: '1234934/AU',
            caseReferenceUrl: 'default.aspx?casekey=1234934/AU',
            issues: ['More than one Related Case matches found', 'No Dates Supplied - Existing Case'],
            propertyType: 'Trade Mark',
            country: 'Australia',
            officialNumber: '9239025-AU',
            caseTitle: 'Comfortable Corn Country Combination Comforters.'
        }]

    };
}

function buildRandomCandidate() {
    var numbers = ['5689', '2345', '1234', '2345', '3456', '4567', '5678', '2343', '8743', '2334'];
    var names = ['Asparagus Farming Pty Ltd', 'Brimstone Holdings Company', 'Origami Corp', 'Cool LLP', 'Honey Corp'];

    var p = Math.floor((Math.random() * 5));
    var f = Math.floor((Math.random() * 5));
    var n = Math.floor((Math.random() * 5));
    var nc = Math.floor((Math.random() * 10));

    var id = nameIdentity++;

    return {
        id: id,
        nameCode: numbers[nc],
        name: names[n],
        formattedName: names[n],
        phone: numbers[p] + ' ' + numbers[p * 2],
        fax: numbers[f] + ' ' + numbers[f * 2],
        email: names[n].replace(/\s+/g, '') + '@' + names[n].replace(/\s+/g, '') + '.com',
        detailsLink: 'desktop.aspx?nameId=' + id
    };
}

function buildMapCandidates(unresolvedNameId) {
    if (!unresolvedNameId) {
        return [{
            nameCode: '002345',
            name: 'Asparagus Farming Equipment Private Limited',
            formattedAddress: '24 Green Street\nBondi NSW 2026',
            phone: '9361 2233',
            fax: '9361 3334',
            email: 'bob.asterisk@asterisk.com',
            contact: 'Hayes, Helen',
            detailsLink: 'desktop.aspx?nameId=-487',
            firstName: 'Helen',
            remarks: 'asparagus'
        }, {
            id: -486,
            nameCode: '445566',
            name: 'Asparagus Production Company',
            formattedAddress: 'PO Box 567\nBalmain NSW 2027',
            phone: '9567 8909',
            fax: '9567 8900',
            detailsLink: 'desktop.aspx?nameId=-486',
            firstName: 'John',
            remarks: 'remarks remarks remarks remarks remarks remarks remarks remarks remarks'
        }, {
            id: -485,
            nameCode: '556677',
            name: 'Asparagus Hydro Solutions Ltd',
            formattedAddress: 'PO Box 578\nBalmain NSW 2027',
            phone: '9568 8909',
            fax: '9568 8900',
            detailsLink: 'desktop.aspx?nameId=-485',
            firstName: 'Ken',
            remarks: 'balmain'
        }, {
            id: -484,
            nameCode: '667788',
            name: 'Asparagus In Your Dish Company',
            formattedAddress: 'PO Box 590\nBalmain NSW 2027',
            phone: '9569 8909',
            fax: '9569 8900',
            detailsLink: 'desktop.aspx?nameId=-484',
            remarks: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
        }, {
            id: -483,
            nameCode: '889900',
            name: 'Asparagus Tastes Yummy Ltd',
            formattedAddress: 'PO Box 610\nBalmain NSW 2027',
            phone: '9560 8909',
            fax: '9560 8900',
            detailsLink: 'desktop.aspx?nameId=-483',
            firstName: 'Bob'
        }];
    }

    var candidates = [];
    for (var i = 0; i < unresolvedNameId; i++) {
        candidates[i] = buildRandomCandidate();
    }
    return candidates;
}

router.get('/api/bulkcaseimport/importstatus*', function(req, res) {
    utils.readJson(path.join(__dirname, '/importStatus.json'), function(data) {
        res.json({
            data: data
        });
    });

});

router.get('/api/bulkcaseimport/filterData/*', function(req, res) {
    res.json({
        result: 'success',
        data: [{ "code": "Error", "description": "Error" }, { "code": "InProgress", "description": "InProgress" }, { "code": "Processed", "description": "Processed" }]
    });
});

router.post('/api/bulkcaseimport/resubmitbatch', function(req, res) {
    res.json({
        result: {
            result: 'success',
            errors: []
        }
    });
});

router.post('/api/bulkcaseimport/reversebatch', function(req, res) {
    res.json({
        result: {
            result: 'success',
            errors: []
        }
    });
});

router.get('/api/bulkcaseimport/permissions', function(req, res) {
    res.json({
        canReverseBatch: true
    });
});

router.get('/api/bulkcaseimport/homeview', function(req, res) {
    res.json({
        viewData: {
            standardTemplates: ['patentImport.xltx', 'trademarkImport.xltx'],
            customTemplates: ['from Sheet law office.csv', 'Brimstone.xltx']
        }
    });
});

router.post('/api/bulkcaseimport/importcases', function(req, res) {
    if (_.indexOf(['invalid.xml', 'invalid.csv'], req.body.fileName) !== -1) {
        res.json({
            result: 'invalid-input',
            errors: [{
                errorMessage: 'Error 1'
            }, {
                errorMessage: 'Error 2'
            }]
        });
    }

    if (_.indexOf(['process-blocked.xml', 'process-blocked.csv'], req.body.fileName) !== -1) {
        res.json({
            result: 'blocked',
            errors: [{
                errorMessage: 'Another staff member is currently using Import Cases. Only one set of data can be imported at a time. Try again soon.'
            }]
        });
    }

    res.json({
        result: 'success',
        requestIdentifier: '1233KJH213'
    });
});

router.get('/api/bulkcaseimport/batchSummary*', function(req, res) {
    res.json(buildBatchSummaryResponse());
});

router.get('/api/bulkcaseimport/batchSummary/batchIdentifier', function(req, res) {
    res.json({
        id: req.query.batchId,
        name: '-batch identifier-',
        transReturnCode: req.query.transReturnCode
    });
});

router.get('/api/bulkcaseimport/batchSummary/filterData/*', function(req, res) {
    res.json({
        result: 'success',
        data: [{ "code": "Error", "description": "Error" }, { "code": "InProgress", "description": "InProgress" }, { "code": "Processed", "description": "Processed" }]
    });
});

router.get('/api/bulkcaseimport/mappingissuesview', function(req, res) {
    res.json({
        viewData: {
            batchId: 5,
            batchIdentifier: 'ABCDEFGHIJKLM',
            mappingIssueCaseCount: 10,
            issueDescription: 'Code mapping rule missing. Please check your mapping rules for ',
            mappingIssues: ['Country: ??',
                'Language: ??'
            ]
        }
    });
});

router.get('/api/bulkcaseimport/nameissuesview', function(req, res) {
    res.json({
        viewData: {
            batchId: 5,
            batchIdentifier: 'ABCDEFGHIJKLM',
            namingIssueCaseCount: 18,
            nameIssues: [{
                id: 1,
                formattedName: 'Farming Equipment Private Limited',
                nameType: 'Client',
                senderNameIdentifier: '00234590',
                formattedAddress: 'George St, \nSydney 2000 NSW',
                phone: '9993 3000',
                fax: '9993 3003',
                email: 'someone@farmingequipment.com',
                contact: 'James, Gillan',
                mapCandidates: buildMapCandidates()
            }, {
                id: 2,
                formattedName: 'Farming Limited',
                nameType: 'Debtor',
                senderNameIdentifier: '00234590'
            }, {
                id: 3,
                formattedName: 'Johnson, Mark',
                nameType: 'Staff Member',
                senderNameIdentifier: 'GG'
            }]
        }
    });
});

router.get('/api/bulkcaseimport/unresolvedname/candidates', function(req, res) {
    var candidates = buildMapCandidates(req.query.id || null);
    if (req.query.candidateId) {
        candidates.splice(0, 0, buildRandomCandidate());
    }
    res.json({
        mapCandidates: candidates
    });
});

router.get('/api/bulkcaseimport/unresolvedname/mapname', function(req, res) {
    res.json({});
});

module.exports = router;