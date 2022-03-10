'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../../../../utils');

router.get('/api/configuration/rules/workflows/:criteriaId/eventcontrol/:eventId', function(req, res) {
    res.json({
        isProtected: !(req.params.criteriaId % 2),
        inheritanceLevel: 'Full',
        canEdit: req.params.eventId % 4,
        criteriaId: req.params.criteriaId,
        eventId: req.params.eventId,
        editBlockedByDescendents: false,
        hasParent: true,
        hasChildren: true,
        canResetInheritance: true,
        overview: {
            baseDescription: 'Fake event control base description',
            data: {
                description: 'Fake event control description',
                notes: 'blah blah',
                maxCycles: 9999,
                importanceLevel: 'important',
                dueDateRespType: 'notApplicable',
                name: null,
                nameType: null
            },
            importanceLevelOptions: [{
                key: 'important',
                value: 'normal'
            }]
        },
        eventOccurrence: {
            dueDateOccurs: 'OnDueDate',
            characteristics: {
                office: {key: 1234, value: 'My Office'},
                caseType: {key: 'A', value: 'Properties'}
            },
            matchJurisdiction: true,
            matchPropertyType: true,
            eventsExist: [{key: -13, value: 'Formal acceptance'}, {key: -13, value: 'Informal acceptance'}]
        },
        dueDateCalcSettings: {
            saveDueDate: 'SaveDueDateOnly',
            extendDueDateBy: 1,
            extendDueDateByUnit: 'M',
            recalcEventDate: true,
            dateToUse: 'E',
            dueDateCalc: true
        },
        standingInstruction: {
            instructionType: {
                key: 'E',
                value: 'Examination'
            },
            characteristicsOptions: [{
                key: 1,
                value: 'abc'
            }, {
                key: 3,
                value: 'def'
            }],
            requiredCharacteristic: 1,
            instructions: ['instruction 1', 'instruction 2']
        },
        datesLogicComparisonType: 'All',
        syncedEventSettings: {
            caseOption: 'RelatedCase',
            useCycle: 'RelatedCaseEvent',
            fromEvent: {
                key: 123,
                value: 'Earliest Priority Date'
            },
            fromRelationship: {
                key: 'BSP',
                code: 'BSP',
                value: 'Basic Application'
            },
            loadNumberType: {
                key: 'A',
                code: 'A',
                value: 'Application No.'
            },
            dateAdjustment: 'E',
            dateAdjustmentOptions: [{
                key: 'Z',
                value: 'Change to 1 July'
            }, {
                key: 'K',
                value: 'Day and Month of Grant Date'
            }, {
                key: 'E',
                value: 'End of Month'
            }, {
                key: '1',
                value: 'Less 1 day'
            }, {
                key: 'M',
                value: 'Less 1 month'
            }, {
                key: 'W',
                value: 'Less 1 week'
            }, {
                key: 'T',
                value: 'Set to todays date'
            }]
        },
        designatedJurisdictions: {
            countryFlagForStopReminders: 32,
            countryFlags: [{
                key: 1,
                value: 'Select at Application'
            }, {
                key: 2,
                value: 'Elect Preliminary Examination'
            }, {
                key: 4,
                value: 'National Phase Entered'
            }, {
                key: 16,
                value: 'Special Action Completed'
            }, {
                key: 32,
                value: 'Abandoned'
            }]
        },
        charges: {
            chargeOne: {
                chargeType: {
                    key: -505,
                    value: 'Miscellaneous Charges'
                },
                isPayFee: true,
                isRaiseCharge: true,
                isEstimate: false,
                isDirectPay: false
            },
            chargeTwo: {
                chargeType: {
                    key: 99998,
                    value: 'Renewal Extension'
                },
                isPayFee: true,
                isRaiseCharge: false,
                isEstimate: true,
                isDirectPay: false
            }
        },
        changeStatus: {
            key: -111,
            value: 'Undergoing Renewal'
        },
        nameChangeSettings: {
            changeNameType: {
                key: 'A',
                code: 'A',
                value: 'Instructor'
            },
            copyFromNameType: {
                key: 'B',
                code: 'B',
                value: 'New Instructor'
            },
            deleteCopyFromName: true,
            moveOldNameToNameType: {
                key: 'C',
                code: 'C',
                value: 'Old Instructor'
            }
        },
        changeAction: {
            openAction: {
                key: 'RN',
                value: 'Renewals'
            },
            closeAction: {
                key: 'RN',
                value: 'Renewals'
            },
            relativeCycle: 3
        },
        report: "on",
        hasDueDateOnCase: true,
        characteristics: {
            caseType: {
                key: 'A',
                value: 'Properties'
            },
            propertyType: {
                key: 'T',
                value: 'Trade Marks'
            },
            jurisdiction: {
                key: 'AT',
                value: 'Austria'
            }
        },
        ptaDelay: 'notApplicable'
    });
});

router.get('/api/configuration/rules/workflows/:criteriaId/eventcontrol/:eventId/nametypemaps', function(req, res) {
    res.json([{
        sequence: 0,
        isInherited: true,
        nameType: {key: 'A', value: 'Agent'},
        caseNameType: {key: 'A', value: 'Agent'},
        mustExist: true
    }, {
        sequence: 1,
        isInherited: false,
        nameType: {key: 'I', value: 'Instructor'},
        caseNameType: {key: 'OI', value: 'Old Instructor'},
        mustExist: false
    }]);
});

router.get('/api/configuration/rules/workflows/:criteriaId/events/:eventId/duedates', function(req, res) {
    utils.readJson(path.join(__dirname, './dueDateCalc.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/configuration/rules/workflows/:criteriaId/eventcontrol/:eventId/datecomparisons', function(req, res) {
    utils.readJson(path.join(__dirname, './dateComparison.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/configuration/rules/workflows/:criteriaId/eventcontrol/:eventId/satisfyingevents', function(req, res) {
    utils.readJson(path.join(__dirname, './satisfyingEvents.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/configuration/rules/workflows/:criteriaId/eventcontrol/:eventId/designatedJurisdictions', function(req, res) {
    utils.readJson(path.join(__dirname, './designatedJurisdictions.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/configuration/rules/workflows/:criteriaId/eventcontrol/:eventId/datesLogic', function(req, res) {
    utils.readJson(path.join(__dirname, './datesLogic.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/configuration/rules/workflows/:criteriaId/eventcontrol/:eventId/eventstoclear', function(req, res) {
    utils.readJson(path.join(__dirname, './eventsToClear.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/configuration/rules/workflows/:criteriaId/eventcontrol/:eventId/eventstoupdate', function(req, res) {
    utils.readJson(path.join(__dirname, './eventsToUpdate.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/configuration/rules/workflows/:criteriaId/eventcontrol/:eventId/reminders', function(req, res) {
    utils.readJson(path.join(__dirname, './reminders.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/configuration/rules/workflows/:criteriaId/eventcontrol/:eventId/documents', function(req, res) {
    utils.readJson(path.join(__dirname, './documents.json'), function(data) {
        res.json(data);
    });
});

router.put('/api/configuration/rules/workflows/:criteriaId/eventControl/:eventId', function(req, res) {
    res.json({
        data: {
            status: 'success'
        }
    });
    // res.json({
    //     data: {
    //         status: 'error',
    //         errors: [{topic: 'dueDateCalc', message: 'Server side error message.'}]
    //     }
    // });
});

module.exports = router;
