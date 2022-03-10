'use strict';

var router = require('express').Router();

router.get('/api/portal/menu', function (req, res) {
    var data = [{
        icon: 'cpa-icon-home',
        url: '#/dashboard',
        text: 'Dashboard'
    },
    {
        icon: 'cpa-icon-advanced-search',
        url: '#/case/search',
        text: 'Case search',
        type: 'searchPanel',
        queryContextKey: 2
    }, {
        icon: 'cpa-icon-clock-o',
        url: '#/accounting/time',
        text: 'Time Recording',
        type: 'newtab'
    },
    {
        icon: 'cpa-icon-lightbulb-o',
        url: '#/cases/index',
        text: 'Cases'
    },
    {
        key: "Utilities",
        icon: "cpa-icon-sliders",
        url: "",
        text: "Utilities",
        description: null,
        type: "simple",
        queryContextKey: null,
        items: [
            {
                "key": "NamesConsolidation",
                "icon": "",
                "url": "#/names/consolidation",
                "text": "Name Consolidation",
                "description": null,
                "type": "simple",
                "queryContextKey": null,
                "items": null
            },
            {
                "key": "HMRCVATSubmission",
                "icon": "",
                "url": "#/accounting/vat",
                "text": "HMRC VAT Submission",
                "description": null,
                "type": "simple",
                "queryContextKey": null,
                "items": null
            }

        ]
    },
    {
        key: "Billing",
        icon: "cpa-icon-file-coins-o",
        url: "",
        text: "Billing",
        description: null,
        type: "simple",
        queryContextKey: null,
        items: [
            {
                "key": "DebitNote",
                "icon": "",
                "url": "#/accounting/billing",
                "text": "Create Debit Note",
                "description": null,
                "type": "simple",
                "queryContextKey": null,
                "items": null
            }
        ]
    },
    {
        key: "WorkInProgress",
        icon: "cpa-icon-wip-o",
        url: "",
        text: "Work In Progress",
        description: null,
        type: "simple",
        queryContextKey: null,
        items: [
            {
                "key": "DisbursementDissection",
                "icon": "",
                "url": "#/accounting/wip-disbursements",
                "text": "Disbursement Dissection",
                "description": null,
                "type": "simple",
                "queryContextKey": null,
                "items": null
            }
        ]
    },
    {
        icon: 'cpa-icon-bell',
        url: null,
        text: 'First',
        items: [{
            icon: 'cpa-icon-arrow-circle-left',
            url: '#/subitem1',
            text: 'SubItem 1'
        },
        {
            icon: 'cpa-icon-align-center',
            url: '#/subitem2',
            text: 'SubItem 2'
        }]
    }
    ];
    res.json(
        data
    );
});

module.exports = router;