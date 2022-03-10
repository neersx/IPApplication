'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../../utils');
var _ = require('underscore');

router.get('/api/configuration/jurisdictions/view', function(req, res) {
    res.json({});
});

router.get('/api/configuration/jurisdictions/search', function(req, res) {
    utils.readJson(path.join(__dirname, './searchResults.json'), function(data) {
        var filtered = search(data, req.query.q);
        var total = filtered.length;
        var params = utils.parseQueryParams(req.query.params);

        filtered = utils.sortAndPaginate(filtered, req.query.params);

        if (params.getAllIds) {
            res.json(_.pluck(filtered, 'id'));
        } else {
            res.json({
                data: filtered,
                pagination: {
                    total: total
                }
            });
        }
    });
});

router.get('/api/configuration/jurisdictions/maintenance/classes/:id', function(req, res) {
    utils.readJson(path.join(__dirname, './classes.json'), function(data) {
        res.json(data);        
    });
});

router.get('/api/configuration/jurisdictions/maintenance/AU', function(req, res) {
    res.json({
        id: 'AU',
        type: '0',
        alternateCode: 'AU',
        name: 'Australia',
        abbreviation: 'AUS',
        postalName: 'Commonwealth of Australia',
        informalName: 'Oz',
        countryAdjective: 'Australian',
        isdCode: '+61',
        reportPriorArt: true,
        notes: 'Australia is a developed country and one of the wealthiest in the world, with the world\'s 12th-largest economy.',
        dateCommenced: '1904-02-13T00:00:00',
        dateCeased: null,
        workDayFlag: 124,
        stateLabel: 'State/Province',
        defaultTaxRate: 'Standard',
        defaultCurrency: 'Australian Dollar',
        defaultCurrencyCode: 'AUD',
        isTaxNumberMandatory: true,
        isInternal: false
    });
});
router.get('/api/configuration/jurisdictions/maintenance/EP', function(req, res) {
    res.json({
        id: 'EP',
        type: '1',
        alternateCode: 'EPO',
        name: 'European Patent Office',
        abbreviation: 'EP',
        postalName: 'European Patent Office',
        informalName: 'EPO',
        countryAdjective: '',
        isdCode: '',
        reportPriorArt: true,
        notes: '',
        dateCommenced: '1904-02-13T00:00:00',
        dateCeased: null,
        workDayFlag: 124,
        isInternal: false
    });
});
router.get('/api/configuration/jurisdictions/maintenance/:id', function(req, res) {
    res.json({
        id: 'GB',
        type: '0',
        alternateCode: 'GB',
        name: 'United Kingdom',
        abbreviation: 'GB',
        postalName: 'United Kingdom',
        informalName: 'Great Britain',
        countryAdjective: 'British',
        isdCode: '+01',
        reportPriorArt: false,
        notes: '',
        dateCommenced: '1904-02-13T00:00:00',
        dateCeased: null,
        workDayFlag: 31,
        defaultTaxRate: 'Standard',
        defaultCurrency: 'Pound Sterling',
        defaultCurrencyCode: 'GBP',
        isTaxNumberMandatory: true
    });
});

router.get('/api/configuration/jurisdictions/maintenance/groups/:id', function(req, res) {
    res.json([{
        id: 'EM',
        name: 'European Community',
        dateCommenced: '1996-04-13T00:00:00.0000000Z    ',
        dateCeased: '',
        isGroupDefault: '',
        defaultDesignation: true,
        isAssociateMember: false
    }, {
        id: 'INT',
        name: 'Internationl Design Deposit',
        dateCommenced: '1960-01-01T00:00:00.0000000Z',
        dateCeased: '',
        isGroupDefault: '',
        defaultDesignation: false,
        isAssociateMember: true
    }]);
});

router.get('/api/configuration/jurisdictions/maintenance/attributes/:id', function(req, res) {
    res.json([{
        typeName: 'Country Attribute',
        value: 'Multi-Class Property Applications Allowed'
    }, {
        typeName: 'Country Attribute',
        value: 'Renew Patents via filing Agent is required'
    }, {
        typeName: 'Language',
        value: 'English'
    }]);
});

router.get('/api/configuration/jurisdictions/maintenance/members/:id', function(req, res) {
    res.json([{
        id: 'BF',
        name: 'Burka Faso',
        dateCommenced: '1901-01-01T00:00:00.0000000Z',
        dateCeased: '1960-01-11T00:00:00.0000000Z',
        fullMembershipDate: '1930-01-11T00:00:00.0000000Z',
        isGroupDefault: true,
        isAssociateMember: true
    }, {
        id: 'BJ',
        name: 'Benin',
        dateCommenced: '1901-01-01T00:00:00.0000000Z',
        dateCeased: '1960-01-11T00:00:00.0000000Z',
        fullMembershipDate: '',
        isGroupDefault: true,
        isAssociateMember: false
    }]);
});

router.get('/api/configuration/jurisdictions/maintenance/texts/:id', function(req, res) {
    res.json([{
        textType: 'Law',
        proeprtyType: 'Trade Mark',
        text: 'Text of Laws'
    }, {
        textType: 'Foul',
        proeprtyType: 'Plant Variety Rights',
        text: 'Text of Chickens'
    }]);
});

router.get('/api/configuration/jurisdictions/maintenance/statusflags/:id', function(req, res) {
    res.json([{
        statusDescription: 'Designated and Filed',
        restrictRemoval: true,
        allowNationalPhase: false,
        registrationStatus: 'Pending'
    }, {
        statusDescription: 'Registered at WIPO',
        restrictRemoval: false,
        allowNationalPhase: true,
        registrationStatus: 'Registered'
    }, {
        statusDescription: 'Refused',
        restrictRemoval: false,
        allowNationalPhase: false,
        registrationStatus: 'Pending'
    }, {
        statusDescription: 'Refusal Received',
        restrictRemoval: false,
        allowNationalPhase: true,
        registrationStatus: 'Pending'
    }, {
        statusDescription: 'Subsequent Designation Filed',
        restrictRemoval: false,
        allowNationalPhase: true,
        registrationStatus: 'Pending'
    }, {
        statusDescription: 'Subs. Designation Regd at WIPO',
        restrictRemoval: false,
        allowNationalPhase: true,
        registrationStatus: 'Registered'
    }]);
});

router.get('/api/configuration/jurisdictions/maintenance/days/:id', function(req, res) {
    res.json([{
        holidayDate: '2017-11-02T00:00:00.0000000Z',
        holiday: 'Day of the Dead'
    }, {
        holidayDate: '2017-12-12T00:00:00.0000000Z',
        holiday: 'Day of the Virgin of Guadalupe'
    }, {
        holidayDate: '2017-05-05T00:00:00.0000000Z',
        holiday: 'Cinco de Mayo'
    }, {
        holidayDate: '2017-01-01T00:00:00.0000000Z',
        holiday: 'New Years Day'
    }, {
        holidayDate: '2017-02-23T00:00:00.0000000Z',
        holiday: 'Chinese New Year'
    }])
});

router.get('/api/configuration/jurisdictions/maintenance/states/:id', function(req, res) {
    res.json([{
        countryCode: 'AU',
        id: 'ACT',
        name: 'Australian Capital Territory'
    }, {
        countryCode: 'AU',
        id: 'NSW',
        name: 'New South Wales'
    }, {
        countryCode: 'AU',
        id: 'NT',
        name: 'Northern Territory'
    }, {
        countryCode: 'AU',
        id: 'QLD',
        name: 'Queensland'
    }, {
        countryCode: 'AU',
        id: 'SA',
        name: 'South Australia'
    }, {
        countryCode: 'AU',
        id: 'VIC',
        name: 'Victoria'
    }, {
        countryCode: 'AU',
        id: 'TAS',
        name: 'Tasmania'
    }, {
        countryCode: 'AU',
        id: 'WA',
        name: 'Western Australia'
    }])
});

router.get('/api/configuration/jurisdictions/maintenance/validnumbers/:id', function(req, res) {
    res.json([{
        propertyType: 'Patent',
        numberType: 'Application No.',
        validFrom: '2017-12-12T00:00:00.0000000Z',
        pattern: '^[0-9]{6}$',
        warningFlag: true,
        errorMessage: "The application number is incorrect. Please change it."
    }, {
        propertyType: 'Trademark',
        numberType: 'Trademark No.',
        validFrom: '2017-12-12T00:00:00.0000000Z',
        pattern: '^[0-9]{6}$',
        warningFlag: false,
        errorMessage: "The trademark number is incorrect. Please change it."
    }])
});

router.get('/api/configuration/jurisdictions/maintenance/combinations/AU', function(req, res) {
    res.json({
        hasCombinations: true
    })
});

router.get('/api/configuration/jurisdictions/maintenance/combinations/:id', function(req, res) {
    res.json({
        hasCombinations: false
    })
});

router.put('/api/configuration/jurisdictions/maintenance/:id', function(req, res) {
    res.json({
        result: 'success',
        updatedId: req.params[0]
    });    
});

function search(data, criteria) {
    if (criteria === null) {
        return data;
    }
    var parsed = JSON.parse(criteria);
    if (parsed.text === '') {
        return data;
    }
    return _.filter(data, function(item) {
        return parsed.isByCode ? item.id.toLowerCase().indexOf(parsed.text.toLowerCase()) > -1 :
            item.name.toLowerCase().indexOf(parsed.text.toLowerCase()) > -1;
    });
}

module.exports = router;
