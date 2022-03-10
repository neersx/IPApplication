'use strict';

var router = require('express').Router();
var fs = require('fs');
var path = require('path');
var _ = require('underscore');

router.get('/api/accounting/time/permissions/*', function(req, res) {
    var permission = {
        canRead: true,
        canInsert: true,
        canUpdate: true,
        canDelete: true,
        canPost: true,
        canAdjustValue: true
    };
    res.json({ data: permission });
});
router.get('/api/accounting/time/list', function(req, res) {
    var totalHours = (Math.floor(Math.random() * 43200));
    var chargeablePercentage = (Math.floor(Math.random() * 100));
    var list = getTime();
    res.json({
        data: {
            data: list,
            pagination: {
                total: list.length
            }
        },
        totals: {
            chargeableSeconds: totalHours * (chargeablePercentage / 100),
            chargeablePercentage: chargeablePercentage,
            totalUnits: Math.round((totalHours / 3600) * (chargeablePercentage / 100) * 6),
            totalHours: totalHours,
            totalValue: (totalHours / 3600) * 60.00
        }
    });
});

router.post('/api/accounting/time/save', function(req, res) {
    res.json({
        response: {
            activity: "abcd",
            caseKey: -457,
            caseReference: "1234/G",
            chargeOutRate: 200,
            elapsedTimeInSeconds: 3600,
            entryNo: 12,
            finish: "2019-07-11T10:19:00",
            foreignCurrency: null,
            foreignDiscount: null,
            foreignValue: null,
            isIncomplete: false,
            isPosted: false,
            localDiscount: 40,
            localValue: 200,
            name: "Asparagus Farming Equipment Pty Ltd",
            narrative: null,
            notes: null,
            staffId: -487,
            start: "2019-07-11T09:19:00",
            totalUnits: 10
        },
        errors: []
    });
});

router.get('/api/accounting/time/evaluateTime', function(req, res) {
    var data = { localValue: 100, localDiscount: 140, foreignValue: 200, foreignDiscount: 300, entryNo: 8 };
    return res.json(data);
});

router.get('/api/accounting/time/view', function(req, res) {
    res.json({ "settings": { "displaySeconds": true, "localCurrencyCode": "AUD", "timeEmptyForNewEntries": false, "restrictOnWip": false, "addEntryOnSave": false, "timeFormat12Hours": true, "hideContinuedEntries": false, "continueFromCurrentTime": true, "unitsPerHour": 10, "roundUpUnits": true, "considerSecsInUnitsCalc": false, "enableUnitsForContinuedTime": false, "valueTimeOnEntry": true }, "userInfo": { "nameId": -487, "displayName": "Grey, George", "canAdjustValues": false, "canFunctionAsOtherStaff": true } });
});

router.get('/api/accounting/time/:caseKey/summary', function(req, res) {
    res.json(getCaseSummary(req.params));
});

router.get('/api/accounting/time/:caseKey/financials', function(req, res) {
    res.json(getCaseFinancials());
});

router.get('/api/accounting/name/:nameKey/receivables', function(req, res) {
    res.json(getNameReceivables());
});

router.get('/api/accounting/:caseKey/agedWipBalances', function(req, res) {
    var data = [];
    data.push({
        entityKey: -283575757,
        entityName: "Maxim Yarrow and Colman Pty Ltd",
        bracket0Total: (Math.floor(Math.random() * 50000)),
        bracket1Total: (Math.floor(Math.random() * 10000)),
        bracket2Total: (Math.floor(Math.random() * 1000)),
        bracket3Total: (Math.floor(Math.random() * 800)),
        total: 0
    });
    data.push({
        entityKey: -283575758,
        entityName: "Green & Curry Pty Ltd",
        bracket0Total: (Math.floor(Math.random() * 50000)),
        bracket1Total: (Math.floor(Math.random() * 10000)),
        bracket2Total: (Math.floor(Math.random() * 1000)),
        bracket3Total: (Math.floor(Math.random() * 500)),
        total: 0
    });
    _.map(data, function(item) {
        item.total = item.bracket0Total + item.bracket1Total + item.bracket2Total + item.bracket3Total;
    });
    res.json(data);
});

router.get('/api/accounting/name/:nameKey/agedReceivableBalances', function(req, res) {
    var data = [];
    data.push({
        entityKey: -283575757,
        entityName: "Ramen & Sons Pty Ltd",
        bracket0Total: (Math.floor(Math.random() * 50000)),
        bracket1Total: (Math.floor(Math.random() * 10000)),
        bracket2Total: (Math.floor(Math.random() * 1000)),
        bracket3Total: (Math.floor(Math.random() * 800)),
        total: 0
    });
    data.push({
        entityKey: -283575758,
        entityName: "Green & Curry Pty Ltd",
        bracket0Total: (Math.floor(Math.random() * 50000)),
        bracket1Total: (Math.floor(Math.random() * 10000)),
        bracket2Total: (Math.floor(Math.random() * 1000)),
        bracket3Total: (Math.floor(Math.random() * 500)),
        total: 0
    });
    _.map(data, function(item) {
        item.total = item.bracket0Total + item.bracket1Total + item.bracket2Total + item.bracket3Total;
    });
    res.json(data);
});

router.get('/api/accounting/time/activities/:caseKey', function(req, res) {
    if (+req.params.caseKey === 110) {
        return res.json({ key: -488, code: "FORAPT", value: "Agents Patents Fees", text: "Foreign Patent Agent fees" });
    } else if (+req.params.caseKey === 111) {
        return res.json({ key: "CONFER", value: "Conference", type: "Chargeable Time - Hourly", typeId: "SERCHG" });
    } else if (+req.params.caseKey === 112) {
        return res.json({ key: "DRAFT", value: "Drafting Specification", type: "Chargeable Time - Hourly", typeId: "SERCHG" });
    } else if (+req.params.caseKey === 113) {
        return res.json({ key: "ZPA", value: "z-Personal Administration", type: "Non-Chargeable Time", typeId: "SERNON" });
    } else if (+req.params.caseKey === 118) {
        return res.json({ key: "EVID", value: "Evidence Preparation", type: "Chargeable Time - Hourly", typeId: "SERCHG" });
    } else {
        return res.json({ key: "EVID", value: "Evidence Preparation", type: "Chargeable Time - Hourly", typeId: "SERCHG" });
    }
});

router.get('/api/accounting/time/narratives/:activityKey', function(req, res) {
    if (req.params.activityKey === "HEAR") {
        return res.json({ key: -488, code: "FORAPT", value: "Agents Patents Fees", text: "Foreign Patent Agent fees" });
    } else if (req.params.activityKey === "CONFER") {
        return res.json({ key: -489, code: "FORATM", value: "Agent's TM Fees", text: "Foreign Trademark Agent fees" });
    } else if (req.params.activityKey === "DISC") {
        return res.json({ key: -465, code: "HEAR", value: "Attend hearing", text: "Attend hearing" });
    } else if (req.params.activityKey === "DRAFT") {
        return res.json({ key: -497, code: "CONFER", value: "Conference", text: "Conference with " });
    } else if (req.params.activityKey === "EVID") {
        return res.json({ key: -497, code: "CONFER", value: "Conference", text: "Conference with " });
    } else {
        return res.json({ key: -497, code: "CONFER", value: "Conference", text: "Conference with " });
    }
});

router.get('/api/accounting/warnings/name/:nameKey', function(req, res) {
    var resData =
    {
        "restriction": {
            "displayName": "Balloon Blast Ball Pty Ltd",
            "nameType": "Instructor",
            "requirePassword": true,
            "debtorStatus": "Bad Payer"
        },
        "caseName":
        {
            "showNameCodeRestriction": true,
            "id": 10048,
            "type": "Instructor",
            "typeId": "I",
            "reference": "BBB25",
            "name": "Balloon Blast Ball Pty Ltd",
            "nameCode": "BBB",
            "nameAndCode": "{BBB} Balloon Blast Ball Pty Ltd",
            "sequenceNo": 0,
            "billingPercentage": null,
            "showBillPercentage": false
        },
        "creditLimitCheckResult":
        {
            "receivableBalance": 16531.13,
            "creditLimit": 500.00,
            "exceeded": true
        }
    };
    return res.json(resData);
});

router.get('/api/accounting/warnings/case/:caseKey', function(req, res) {
    var resData =
    {
        budgetCheckResult: {
            "budget": {
                "revised": 10000,
                "original": 12000,
                "start": null,
                "end": null
            },
            "percentageUsed": 10.25,
            "billedTotal": 1000,
            "unbilledTotal": 2000,
            "usedTotal": 3500.00
        },
        caseWipWarnings:
            [{
                "restriction": {
                    "displayName": "Balloon Blast Ball Pty Ltd",
                    "nameType": "Instructor",
                    "requirePassword": true,
                    "debtorStatus": "Bad Payer"
                },
                "caseName":
                {
                    "showNameCodeRestriction": true,
                    "id": 10048,
                    "type": "Instructor",
                    "typeId": "I",
                    "reference": "BBB25",
                    "name": "Balloon Blast Ball Pty Ltd",
                    "nameCode": "BBB",
                    "nameAndCode": "{BBB} Balloon Blast Ball Pty Ltd",
                    "sequenceNo": 0,
                    "billingPercentage": null,
                    "showBillPercentage": false,
                    "debtorStatus": "Bad Payer",
                    "displayName": "Balloon Blast Ball Pty Ltd"
                },
                "creditLimitCheckResult":
                {
                    "receivableBalance": 16531.13,
                    "creditLimit": 500.00,
                    "exceeded": true
                }
            }, {
                "restriction": {
                    "displayName": "Debtor 2",
                    "nameType": "Instructor",
                    "requirePassword": true,
                    "debtorStatus": "Don't like them!"
                },
                "caseName":
                {
                    "showNameCodeRestriction": true,
                    "id": 10050,
                    "nameType": "Instructor",
                    "typeId": "I",
                    "reference": "ccc25",
                    "name": "Debtor 2",
                    "nameCode": "ccc",
                    "nameAndCode": "{ccc} Debtor 2",
                    "sequenceNo": 0,
                    "billingPercentage": null,
                    "showBillPercentage": false,
                    "debtorStatus": "Don't like them!",
                    "displayName": "Debtor 2"
                },
                "creditLimitCheckResult":
                {
                    "receivableBalance": 10500.13,
                    "creditLimit": 100.00,
                    "exceeded": true
                }
            }]
    };
    return res.json(resData);
});

router.post('/api/accounting/warnings/validate/', function() {
    return true;
});

router.get('/api/accounting/time/checkstatus/:caseKey', function(req, res) {
    return res.json(true);
});

router.get('/api/accounting/time-posting/view', function(req, res) {
    var resData = {
        entities: [{ id: 1, displayName: 'Green & Curry', isDefault: false }, { id: 2, displayName: 'Mike Ross and Partners', isDefault: true }],
        hasFixedEntity: false,
        postCaseToOfficeEntity: false
    };

    return res.json(resData);
});

router.get('/api/accounting/time-posting/getDates', function(req, res) {
    var data = [];
    var date = new Date();
    for (var i = 0; i < 10; i++) {
        var elapsedTime = (Math.floor(Math.random() * 43200));
        data.push({
            date: date.setDate(date.getDate() + i),
            totalTimeInSeconds: elapsedTime,
            totalChargableTimeInSeconds: elapsedTime
        });
    }

    return res.json(data);
});

router.get('/api/accounting/time/gaps', function(req, res) {
    res.json(
        [{
            startTime: "2020-04-15T00:00:00",
            finishTime: "2020-04-15T01:00:00",
            duration: "01:00:00",
            durationInSeconds: 3600.0
        },
        {
            startTime: "2020-04-15T02:00:00",
            finishTime: "2020-04-15T23:59:59",
            duration: "21:59:59",
            durationInSeconds: 79199.0
        }]
    );
});

function getTime() {
    var data = [];
    for (var i = 0; i < 10; i++) {
        var elapsedTime = (Math.floor(Math.random() * 43200));
        var rate = 60.00;
        var discount = 5.00;
        var hasForeign = ((Math.floor(Math.random() * 10)) % 2 > 0);
        var currentDate = new Date();
        var start = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate(), 7 + i);
        var end = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate(), 7 + i, null, elapsedTime);
        var notes = 'Notes ' + i.toString();
        var narrative = 'Narrative ' + i.toString();
        data.push({
            entryNo: i,
            start: start,
            finish: end,
            elapsedTimeInSeconds: elapsedTime,
            name: ((Math.floor(Math.random() * 10)) % 2 > 0) ? "Green & Curry" : "Ramen & Sons",
            caseKey: ((Math.floor(Math.random() * 10)) % 2 > 0) ? 13 : 8,
            caseReference: ((Math.floor(Math.random() * 10)) % 2 > 0) ? "0001234/GB/" + elapsedTime : "0001234/US/" + elapsedTime,
            activity: ((Math.floor(Math.random() * 10)) % 2 > 0) ? "Evidence preparation" : "General Correspondence",
            localValue: elapsedTime * rate,
            foreignValue: hasForeign ? elapsedTime * rate : null,
            foreignCurrency: hasForeign ? ((Math.floor(Math.random() * 10)) % 2 > 0) ? "GBP" : "USD" : null,
            notes: notes,
            narrative: narrative,
            chargeOutRate: rate,
            localDiscount: elapsedTime * discount,
            foreignDiscount: hasForeign ? elapsedTime * discount : null,
            totalUnits: elapsedTime * 3600 / 60,
            isPosted: false// ((Math.floor(Math.random() * 10)) % 2 > 0) ? false : true
        });
    }
    data.push({
        caseReference: "0001234/AU/001",
        name: "Mike Ross & Partners",
        isIncomplete: true
    });
    return data;
}

function getCaseSummary(params) {
    var caseKey = params['caseKey'];
    var data = fs.readFileSync(path.join(__dirname, '/caseSummary.json'));
    var result = JSON.parse(data);
    result.caseKey = caseKey;
    result.irn += ('/' + caseKey);
    result.activeBudget = { original: 5, revised: 6 };
    return result;
}

function getCaseFinancials() {
    var data = {
        "unpostedTime": 500,
        "wip": (Math.floor(Math.random() * 50000)),
        "totalWorkPerformed": 6000.33,
        "activeBudget": 10000.00,
        "budgetUsed": 60
    }
    return data;
}

function getNameReceivables() {
    var data = {
        data: {
            "receivableBalance": (Math.floor(Math.random() * 10000))
        }
    }
    return data;
}

module.exports = router;