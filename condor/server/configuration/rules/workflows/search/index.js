'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../../../../utils');
var _ = require('underscore');

function search(data, ids) {
    if (!ids) {
        return data;
    }
    ids = JSON.parse(ids);
    if (!ids.length) {
        return data;
    }
    ids = _.map(ids, function(id) {
        return parseInt(id);
    });

    return _.filter(data, function(item) {
        return item.id && ids.indexOf(item.id) > -1;
    });
}

router.get('/api/configuration/rules/workflows/typeaheadSearch', function(req, res) {
    utils.readJson(path.join(__dirname, '/criteriaTypeahead.json'), function(data) {
        var searchValue = req.query.search || '';
        var total = data.length;

        if (searchValue) {
            data = data.filter(function(item) {
                return item.description.toUpperCase().indexOf(searchValue.toUpperCase()) !== -1 || item.id.toString().indexOf(search) !== -1;
            });
        }

        res.json({
            data: data,
            pagination: {
                total: total
            }
        });
    });
});

router.get('/api/configuration/rules/workflows/search*', function(req, res) {
    utils.readJson(path.join(__dirname, './criteriaSearchResults.json'), function(data) {
        var filtered = search(data, req.query.q);
        var params = utils.parseQueryParams(req.query.params);

        filtered = utils.filterGridResultsOnCodeProperty(filtered, req.query.params);

        var total = filtered.length;
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

router.get('/api/configuration/rules/characteristics/validateCharacteristics', function(req, res) {
    var criteria = JSON.parse(req.query.criteria);
    var hasJurisdiction = criteria.jurisdiction;
    setTimeout(function() {
        res.json({
            caseType: {
                isValid: true
            },
            caseCategory: {
                isValid: !criteria.caseCategory || hasJurisdiction
            },
            jurisdiction: {
                isValid: true
            },
            subType: {
                isValid: !criteria.subType || hasJurisdiction
            },
            propertyType: {
                isValid: !criteria.propertyType || hasJurisdiction
            },
            basis: {
                isValid: !criteria.basis || hasJurisdiction
            },
            action: {
                isValid: !criteria.action || hasJurisdiction
            },
            office: {
                isValid: true
            },
            dateOfLaw: {
                isValid: true
            }
        });
    }, 200);
});

router.get('/api/configuration/rules/workflows/filterData/:column', function(req, res) {
    var gridResultsPath = path.join(__dirname, './criteriaSearchResults.json');

    utils.readColumnData(gridResultsPath, req.params.column, function(data) {
        res.json(data);
    });
});


router.get('/api/configuration/rules/workflows/view', function(req, res) {
    res.json({
        hasOffices: true
    });
});

router.get('api/configuration/rules/characteristics/caseCharacteristics/*', function(req, res) {
    res.json({
        caseType: {
            key: 'A',
            value: 'Properties',
            isValid: true
        },
        jurisdiction: {
            key: 'AU',
            value: 'Australia',
            isValid: true
        },
        subType: {
            key: 'V',
            value: 'Vines/Potatoes/Trees',
            isValid: true
        },
        propertyType: {
            key: 'D',
            value: 'Designs',
            isValid: true
        },
        applyTo: 'local-clients'
    });
});

router.get('/api/configuration/rules/workflows/defaultDateOfLaw', function(req, res) {
    res.json({
        key: '1996-01-01T00:00:00',
        value: '01-Jan-1996'
    });
});

router.get('/api/configuration/rules/workflows/:id', function(req, res) {
    res.json({
        criteriaId: parseInt(req.params.id),
        criteriaName: 'My Criteria',
        isProtected: !(req.params.id % 2),
        isInherited: !(req.params.id % 3),
        canEdit: Boolean(req.params.id % 2),
        hasOffices: true,
        isHighestParent: (req.params.id % 3)
    });
});

module.exports = router;
