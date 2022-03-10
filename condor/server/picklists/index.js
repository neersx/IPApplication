'use strict';

var express = require('express');
var _ = require('underscore');
var router = express.Router();
var fs = require('fs');
var path = require('path');
var utils = require('../utils');

function instructionsByType(filterType) {
    var all = JSON.parse(fs.readFileSync(path.join(__dirname, '/instructions.json')));

    if (!filterType) {
        return all;
    }

    return _.filter(all, function (item) {
        return item.typeId === filterType;
    });
}

function filterBySearchText(all, searchText, codeField) {
    if (!searchText || searchText === '') {
        return all;
    }
    searchText = searchText.toUpperCase();

    return _.filter(all, function (item) {
        return item[codeField] && item[codeField].toString().toUpperCase().indexOf(searchText) > -1 || item.value && item.value.toUpperCase().indexOf(searchText) > -1;
    });
}

function markExactMatches(all, searchText, codeField) {
    if (!searchText || searchText === '') {
        return all;
    }

    searchText = searchText.toUpperCase();
    return _.map(all, function (item) {
        if (!codeField) {
            item.exactMatch = item.value && item.value.toUpperCase() === searchText;
        } else {
            item.exactMatch = item[codeField] && item[codeField].toString().toUpperCase() === searchText || item.value && item.value.toUpperCase() === searchText;
        }
        return item;
    });
}

function populate(config, req, res, next, queryFilter) {
    utils.readJson(path.join(__dirname, config.path), function (data, err) {
        if (err) {
            return next(err);
        }

        var filtered = filterBySearchText(data, req.query.search, config.key);
        var total = filtered.length;

        if (queryFilter) {
            filtered = queryFilter(filtered);
            total = filtered.length;
        }

        filtered = utils.sortAndPaginate(filtered, req.query.params);
        filtered = markExactMatches(filtered, req.query.search, config.exactMatchKey);

        if (config.metaData) {
            res.json(_.extend({
                data: filtered,
                pagination: {
                    total: total
                }
            },
                config.metaData));
        } else {
            res.json({
                data: filtered,
                pagination: {
                    total: total
                }
            });
        }
    });
}

var instructionTypesMeta = {
    columns: [{
        field: 'key',
        hidden: true,
        key: true
    }, {
        title: 'picklist.instructiontype.Code',
        field: 'code',
        code: true
    }, {
        title: 'picklist.instructiontype.Description',
        field: 'value',
        description: true
    }, {
        title: 'picklist.instructiontype.RecordedAgainst',
        field: 'recordedAgainst'
    }, {
        title: 'picklist.instructiontype.RestrictedBy',
        field: 'restrictedBy'
    }],
    maintainability: {
        canAdd: true,
        canEdit: true,
        canDelete: true
    }
};

router.get('/api/picklists/instructionTypes', function (req, res) {
    utils.readJson(path.join(__dirname, '/instructionTypes.json'), function (data) {
        var filtered = filterBySearchText(data, req.query.search, 'code');
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        filtered = markExactMatches(filtered, req.query.search, 'code');

        setTimeout(function () {
            res.json(_.extend({
                data: filtered,
                pagination: {
                    total: total
                }
            }, instructionTypesMeta));
        }, parseInt(req.query.latency || 0));
    });
});

router.get('/api/picklists/instructionTypes/meta', function (req, res) {
    res.json(instructionTypesMeta);
});

router.get('/api/picklists/instructionTypes/*', function (req, res) {
    var nameTypes = req.params[0] === 'nameTypes';
    var dataPath = nameTypes ? '/nameTypes.json' : '/instructionTypes.json';

    utils.readJson(path.join(__dirname, dataPath), function (data) {
        if (nameTypes) {
            res.json(_.reject(data, function (item) {
                return item.code === '~~~';
            }));
        } else {
            res.json({
                data: _.find(data,
                    function (item) {
                        return item.key === req.params[0];
                    }
                )
            });
        }
    });
});

router.delete('/api/picklists/instructionTypes/*', function (req, res) {
    res.json({
        result: 'success'
    });
});

router.put('/api/picklists/instructionTypes/*', function (req, res) {
    res.json({
        result: 'success'
    });
});

router.post('/api/picklists/instructionTypes', function (req, res) {
    res.json({
        result: 'success'
    });
});

var instructionsMeta = {
    columns: [{
        field: 'id',
        hidden: true,
        key: true
    }, {
        title: 'picklist.instruction.Description',
        field: 'description',
        description: true
    }, {
        title: 'picklist.instruction.TypeDescription',
        field: 'typeDescription'
    }],
    maintainability: {
        canAdd: true,
        canEdit: true,
        canDelete: true
    }
};

router.get('/api/picklists/instructions', function (req, res) {
    var all = instructionsByType(req.query.typeId);
    var filtered = filterBySearchText(all, req.query.search, 'code');
    var total = filtered.length;
    filtered = utils.sortAndPaginate(filtered, req.query.params);
    filtered = markExactMatches(filtered, req.query.search, 'code');

    res.json(_.extend({
        data: filtered,
        pagination: {
            total: total
        }
    }, instructionsMeta));
});

router.get('/api/picklists/instructions/meta', function (req, res) {
    res.json(instructionsMeta);
});

router.get('/api/picklists/instructions/*', function (req, res) {
    var instructionTypes = req.params[0] === 'instructionTypes';
    var dataPath = instructionTypes ? '/instructionTypes.json' : '/instructions.json';

    utils.readJson(path.join(__dirname, dataPath), function (data) {
        if (instructionTypes) {
            res.json(_.reject(data, function (item) {
                return item.code === '~~~';
            }));
        } else {
            res.json({
                data: _.find(data,
                    function (item) {
                        return item.id === req.params[0];
                    }
                )
            });
        }
    });
});

router.delete('/api/picklists/instructions/*', function (req, res) {
    res.json({
        result: 'success'
    });
});

router.put('/api/picklists/instructions/*', function (req, res) {
    res.json({
        result: 'success'
    });
});

router.post('/api/picklists/instructions', function (req, res) {
    res.json({
        result: 'success'
    });
});

var officeMeta = {
    columns: [{
        field: 'key',
        hidden: true,
        key: true
    }, {
        title: 'picklist.office.Description',
        field: 'value',
        description: true
    }, {
        title: 'picklist.office.Organisation',
        field: 'organisation',
        description: true
    }, {
        title: 'picklist.office.Country',
        field: 'country',
        description: true
    }, {
        title: 'picklist.office.DefaultLanguage',
        field: 'defaultLanguage',
        description: true
    }],
    maintainability: {
        canAdd: false,
        canEdit: false,
        canDelete: false
    }
};

router.get('/api/picklists/offices/meta', function (req, res) {
    res.json(officeMeta);
});

router.get('/api/picklists/offices', function (req, res, next) {
    var config = {
        path: '/offices.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: officeMeta
    };

    populate(config, req, res, next);
});


var tagsMeta = {
    columns: [{
        field: 'key',
        hidden: true,
        key: true
    }, {
        field: 'id',
        hidden: true,
        code: true
    }, {
        title: 'picklist.tags.Description',
        field: 'tagName',
        description: true
    }],
    maintainability: {
        canAdd: false,
        canEdit: false,
        canDelete: false
    }
};

router.get('/api/picklists/tags/meta', function (req, res) {
    res.json(tagsMeta);
});

router.get('/api/picklists/tags', function (req, res, next) {
    var config = {
        path: '/tags.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: tagsMeta
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/profile', function (req, res, next) {
    var config = {
        path: '/profile.json',
        key: 'key',
        exactMatchKey: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/taskPlannerSavedSearch', function (req, res, next) {
    var config = {
        path: '/taskPlannerSavedSearch.json',
        key: 'key',
        exactMatchKey: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/profitcentre', function (req, res, next) {
    var config = {
        path: '/profitCentre.json',
        key: 'code',
        exactMatchKey: 'code'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/program', function (req, res, next) {
    var config = {
        path: '/program.json',
        key: 'key',
        exactMatchKey: 'key'
    };

    populate(config, req, res, next);
});

var caseTypeMeta = {
    columns: [{
        field: 'key',
        hidden: true,
        key: true
    }, {
        title: 'picklist.casetype.Description',
        field: 'value',
        description: true
    }],
    maintainability: {
        canAdd: false,
        canEdit: false,
        canDelete: false
    }
};

router.get('/api/picklists/casetypes/meta', function (req, res) {
    res.json(caseTypeMeta);
});

router.get('/api/picklists/casetypes', function (req, res, next) {
    var config = {
        path: '/caseTypes.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: caseTypeMeta
    };

    populate(config, req, res, next);
});

var casesMeta = {
    columns: [{
        title: 'picklist.case.Id',
        field: 'key',
        hidden: true,
        key: true
    }, {
        title: 'picklist.case.CaseRef',
        field: 'code',
        description: true
    }, {
        title: 'picklist.case.Title',
        field: 'value',
        description: true
    }, {
        title: 'picklist.case.OfficialNumber',
        field: 'officialNumber',
        description: true
    }, {
        title: 'picklist.case.PropertyType',
        field: 'propertyTypeDescription',
        description: true
    }, {
        title: 'picklist.case.Country',
        field: 'countryName',
        description: true
    }],
    maintainability: {
        canAdd: false,
        canEdit: false,
        canDelete: false
    }
};

router.get('/api/picklists/cases/meta', function (req, res) {
    res.json(casesMeta);
});

router.get('/api/picklists/cases', function (req, res, next) {
    var config = {
        path: '/cases.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: casesMeta
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/cases/instructor?*', function (req, res, next) {
    var config = {
        path: '/cases.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: casesMeta
    };

    populate(config, req, res, next);
});


var jurisdictionsMeta = {
    columns: [{
        title: 'picklist.jurisdiction.Code',
        field: 'key',
        hidden: false,
        key: true,
        code: true
    }, {
        title: 'picklist.jurisdiction.Description',
        field: 'value',
        hidden: false,
        description: true
    }],
    maintainability: {
        canAdd: false,
        canEdit: false,
        canDelete: false
    }
};

router.get('/api/picklists/jurisdictions/meta', function (req, res) {
    res.json(jurisdictionsMeta);
});

router.get('/api/picklists/jurisdictions/*', function (req, res, next) {
    var config = {
        path: '/jurisdictions.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: jurisdictionsMeta
    };

    populate(config, req, res, next);
});


router.get('/api/picklists/jurisdictions*', function (req, res, next) {
    var config = {
        path: '/jurisdictions.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: jurisdictionsMeta
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/designatedjurisdictions', function (req, res, next) {
    var config = {
        path: '/jurisdictions.json',
        key: 'key',
        exactMatchKey: 'key'
    };

    populate(config, req, res, next);
});

var propertyTypesMeta = {
    columns: [{
        title: 'picklist.propertytype.Code',
        field: 'key',
        hidden: false,
        key: true,
        code: true
    }, {
        title: 'picklist.propertytype.Description',
        field: 'value',
        description: true
    }],
    maintainability: {
        canAdd: false,
        canEdit: false,
        canDelete: false
    }
};

router.get('/api/picklists/propertyTypes/meta', function (req, res) {
    res.json(propertyTypesMeta);
});

router.get('/api/picklists/propertyTypes', function (req, res, next) {
    var config = {
        path: '/propertyTypes.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: propertyTypesMeta
    };

    populate(config, req, res, next);
});

var subTypeMeta = {
    columns: [{
        title: 'picklist.subtype.Code',
        field: 'key',
        hidden: false,
        key: true,
        code: true
    }, {
        title: 'picklist.subtype.Description',
        field: 'value',
        description: true
    }],
    maintainability: {
        canAdd: false,
        canEdit: false,
        canDelete: false
    }
};

router.get('/api/picklists/subtypes/meta', function (req, res) {
    res.json(subTypeMeta);
});

router.get('/api/picklists/subtypes', function (req, res, next) {
    var config = {
        path: '/subTypes.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: subTypeMeta
    };

    populate(config, req, res, next);
});


var actionsMeta = {
    columns: [{
        title: 'picklist.action.Code',
        field: 'key',
        hidden: false,
        key: true,
        code: true
    }, {
        title: 'picklist.action.Description',
        field: 'value',
        description: true
    }, {
        title: 'picklist.action.Cycles',
        field: 'cycles'
    }],
    maintainability: {
        canAdd: false,
        canEdit: false,
        canDelete: false
    }
};

router.get('/api/picklists/actions/meta', function (req, res) {
    res.json(actionsMeta);
});

router.get('/api/picklists/actions', function (req, res, next) {
    var config = {
        path: '/actions.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: actionsMeta
    };

    populate(config, req, res, next);
});

var caseCategoriesMeta = {
    columns: [{
        title: 'picklist.casecategory.Code',
        field: 'key',
        hidden: false,
        key: true,
        code: true
    }, {
        title: 'picklist.casecategory.Description',
        field: 'value',
        description: true
    }],
    maintainability: {
        canAdd: false,
        canEdit: false,
        canDelete: false
    }
};

router.get('/api/picklists/caseCategories/meta', function (req, res) {
    res.json(caseCategoriesMeta);
});

router.get('/api/picklists/caseCategories', function (req, res, next) {
    var config = {
        path: '/caseCategories.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: caseCategoriesMeta
    };

    populate(config, req, res, next);
});

var dateOfLawMeta = {
    columns: [{
        field: 'key',
        hidden: true,
        key: true
    }, {
        title: 'picklist.dateoflaw.DateOfLaw',
        field: 'value',
        description: true
    }, {
        title: 'picklist.dateoflaw.RetrospectiveAction',
        field: 'retrospectiveAction',
        description: true
    }, {
        title: 'picklist.dateoflaw.DefaultEventForLaw',
        field: 'defaultEventForLaw',
        description: true
    }, {
        title: 'picklist.dateoflaw.DefaultRetrospectiveEvent',
        field: 'defaultRetrospectiveEvent',
        description: true
    }],
    maintainability: {
        canAdd: false,
        canEdit: false,
        canDelete: false
    }
};

router.get('/api/picklists/datesoflaw/meta', function (req, res) {
    res.json(dateOfLawMeta);
});

router.get('/api/picklists/datesoflaw', function (req, res, next) {
    var config = {
        path: '/datesOfLaw.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: dateOfLawMeta
    };

    populate(config, req, res, next);
});

var basisMeta = {
    columns: [{
        title: 'picklist.basis.Code',
        field: 'key',
        hidden: false,
        key: true,
        code: true
    }, {
        title: 'picklist.basis.Description',
        field: 'value',
        description: true
    }]
};

router.get('/api/picklists/basis/meta', function (req, res) {
    res.json(basisMeta);
});

router.get('/api/picklists/basis', function (req, res, next) {
    var config = {
        path: '/basis.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: subTypeMeta
    };

    populate(config, req, res, next);
});

var eventsMeta = {
    columns: [{
        title: 'picklist.event.EventNo',
        field: 'key',
        key: true,
        menu: true
    }, {
        title: 'picklist.event.Code',
        field: 'code',
        menu: true
    }, {
        title: 'picklist.event.Description',
        field: 'value',
        description: true
    }, {
        title: 'picklist.event.Alias',
        field: 'alias',
        sortbale: false,
        menu: true
    }, {
        title: 'picklist.event.MaxCycles',
        field: 'maxCycles',
        sortable: false,
        menu: true
    }, {
        title: 'picklist.event.Importance',
        field: 'importance',
        menu: true
    }, {
        title: 'picklist.event.EventCategory',
        field: 'eventCategory',
        menu: true
    }, {
        title: 'picklist.event.EventGroup',
        field: 'eventGroup',
        menu: true
    }, {
        title: 'picklist.event.EventNotesGroup',
        field: 'eventNotesGroup',
        menu: true
    }],
    maintainability: {
        canAdd: true,
        canEdit: true,
        canDelete: true
    },
    ids: [-1011828, -1011785, -1011761, -1011403, -1011386, -1011384, -1011378, -1000153, -1000023, -12126]
};

router.get('/api/picklists/events', function (req, res, next) {
    var config = {
        path: '/events.json',
        key: 'key',
        exactMatchKey: 'key',
        metaData: eventsMeta,
        picklistCanMaintain: true
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/events/meta', function (req, res) {
    res.json(eventsMeta);
});

var checklistsMeta = {
    columns: [{
        title: 'picklist.checklistmatcher.Code',
        field: 'code',
        key: true,
        code: true
    }, {
        title: 'picklist.checklistmatcher.Description',
        field: 'value',
        description: true
    }]
};

router.get('/api/picklists/checklist', function (req, res, next) {
    var config = {
        path: '/checklists.json',
        key: 'code',
        exactMatchKey: 'code',
        metaData: checklistsMeta
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/checklist/meta', function (req, res) {
    res.json(checklistsMeta);
});

var relationshipMeta = {
    columns: [{
        title: 'picklist.relationship.Code',
        field: 'code',
        key: true,
        code: true
    }, {
        title: 'picklist.relationship.Description',
        field: 'value',
        description: true
    }]
};

router.get('/api/picklists/relationship', function (req, res, next) {
    var config = {
        path: '/relationships.json',
        key: 'code',
        exactMatchKey: 'code',
        metaData: relationshipMeta
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/relationship/meta', function (req, res) {
    res.json(relationshipMeta);
});

router.get('/api/picklists/status/meta', function (req, res) {
    res.json({
        columns: [{
            title: 'picklist.status.Description',
            field: 'value',
            description: true
        }, {
            title: 'picklist.status.Type',
            field: 'type'
        }]
    });
});

router.get('/api/picklists/status', function (req, res, next) {
    utils.readJson(path.join(__dirname, '/status.json'), function (data, err) {
        if (err) {
            return next(err);
        }

        if (req.query.isRenewal != null) {
            var r = req.query.isRenewal === 'true' ? 'Renewal' : 'Case';
            data = _.filter(data, function (item) {
                return item['type'] === r;
            });
        }

        var filtered = filterBySearchText(data, req.query.search, 'key');
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        filtered = markExactMatches(filtered, req.query.search, 'key');

        res.json(_.extend({
            data: filtered,
            pagination: {
                total: total
            }
        },
            relationshipMeta));
    });
});

router.get('/api/picklists/texttypes', function (req, res, next) {
    var config = {
        path: '/texttype.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/eventCategory', function (req, res, next) {
    var config = {
        path: '/eventCategory.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/fileLocations', function (req, res, next) {
    var config = {
        path: '/fileLocations.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/chargeTypes', function (req, res, next) {
    var config = {
        path: '/chargeTypes.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/numbertypes', function (req, res, next) {
    var config = {
        path: '/numberTypes.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

var dataItemsMeta = {
    columns: [{
        title: 'picklist.dataitem.Code',
        field: 'code',
        code: true
    }, {
        title: 'picklist.dataitem.Description',
        field: 'value',
        description: true
    }]
};

router.get('/api/picklists/dataitems', function (req, res, next) {
    var config = {
        path: '/dataItems.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/dataitems/meta', function (req, res) {
    res.json(dataItemsMeta);
});

router.get('/api/picklists/documents', function (req, res, next) {
    var config = {
        path: '/documents.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/availabletopic', function (req, res, next) {
    var config = {
        path: '/availabletopic.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/designationstage', function (req, res, next) {
    var config = {
        path: '/designationStages.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/nametypegroups', function (req, res, next) {
    var config = {
        path: '/nameTypeGroups.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/names', function (req, res, next) {
    var config = {
        path: '/names.json',
        key: 'displayName',
        exactMatchKey: 'code',
        metaData: {
            columns: [{
                "field": "key",
                "hidden": true
            }, {
                "title": "picklist.name.Code",
                "field": "code",
                "sortable": true
            }, {
                "title": "picklist.name.Name",
                "field": "displayName",
                "sortable": true
            }, {
                "title": "picklist.name.Remarks",
                "field": "remarks",
                "sortable": true
            }]
        }
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/names/:key', function (req, res) {
    utils.readJson(path.join(__dirname, '/names.json'), function (data) {
        res.json({
            data: _.find(data,
                function (item) {
                    return item.key.toString() === req.params.key;
                }
            )
        });
    });
});

router.get('/api/picklists/roles', function (req, res, next) {
    var config = {
        path: '/roles.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/images', function (req, res, next) {
    var config = {
        path: '/images.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/internalUsers', function (req, res, next) {
    var config = {
        path: '/internalUsers.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/dataDownloadCaseQueries', function (req, res, next) {
    var config = {
        path: '/dataDownloadCaseQueries.json',
        key: 'key'
    };

    populate(config, req, res, next);
});

router.get('/api/picklists/certificate-customers', function (req, res, next) {
    var config = {
        path: '/customers.json',
        key: 'key'
    };

    populate(config, req, res, next, function (data) {
        return _.filter(data, function (item) {
            return item.certificateId === req.query.certificateId;
        });
    });
});


var caseFamiliesMeta = {
    columns: [{
        title: 'picklist.casefamily.key',
        field: 'key',
        key: true,
        code: true
    }, {
        title: 'picklist.casefamily.description',
        field: 'value',
        description: true
    }, {
        title: 'picklist.casefamily.inUse',
        field: 'inUse',
        dataType: 'boolean'
    }],
    maintainability: {
        canAdd: false,
        canEdit: false,
        canDelete: false
    }
};

router.get('/api/picklists/caseFamilies', function (req, res) {
    utils.readJson(path.join(__dirname, '/caseFamilies.json'), function (data) {
        var filtered = filterBySearchText(data, req.query.search, 'code');
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        filtered = markExactMatches(filtered, req.query.search, 'code');

        setTimeout(function () {
            res.json(_.extend({
                data: filtered,
                pagination: {
                    total: total
                }
            }, caseFamiliesMeta));
        }, parseInt(req.query.latency || 0));
    });
});

router.get('/api/picklists/caseFamilies/meta', function (req, res) {
    res.json(caseFamiliesMeta);
});

router.get('/api/picklists/caseFamilies/*', function (req, res) {
    utils.readJson(path.join(__dirname, '/caseFamilies.json'), function (data) {
        res.json({
            data: _.find(data,
                function (item) {
                    return item.key === req.params[0];
                }
            )
        });
    });
});


var caseListsMeta = {
    columns: [{
        field: 'key',
        key: true,
        code: true,
        hidden: true
    }, {
        title: 'picklist.caselist.caseList',
        field: 'value',
        description: true
    }, {
        title: 'picklist.caselist.description',
        field: 'description',
        description: true
    }],
    maintainability: {
        canAdd: false,
        canEdit: false,
        canDelete: false
    }
};

router.get('/api/picklists/caseLists', function (req, res) {
    utils.readJson(path.join(__dirname, '/caseLists.json'), function (data) {
        var filtered = filterBySearchText(data, req.query.search, 'description');
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        filtered = markExactMatches(filtered, req.query.search, 'code');

        setTimeout(function () {
            res.json(_.extend({
                data: filtered,
                pagination: {
                    total: total
                }
            }, caseListsMeta));
        }, parseInt(req.query.latency || 0));
    });
});

router.get('/api/picklists/caseLists/meta', function (req, res) {
    res.json(caseListsMeta);
});

router.get('/api/picklists/caseLists/*', function (req, res) {
    utils.readJson(path.join(__dirname, '/caseLists.json'), function (data) {
        res.json({
            data: _.find(data,
                function (item) {
                    return item.key === req.params[0];
                }
            )
        });
    });
});


var keywordsMeta = {
    columns: [{
        title: 'picklist.keyword.keyword',
        field: 'key',
        description: true
    }, {
        title: 'picklist.keyword.stopWord',
        field: 'isStopWord',
        dataType: 'boolean'
    }],
    maintainability: {
        canAdd: false,
        canEdit: false,
        canDelete: false
    }
};

router.get('/api/picklists/keywords', function (req, res) {
    utils.readJson(path.join(__dirname, '/keywords.json'), function (data) {
        var filtered = filterBySearchText(data, req.query.search, 'key');
        var total = filtered.length;

        setTimeout(function () {
            res.json(_.extend({
                data: filtered,
                pagination: {
                    total: total
                }
            }, keywordsMeta));
        }, parseInt(req.query.latency || 0));
    });
});

router.get('/api/picklists/keywords/meta', function (req, res) {
    res.json(keywordsMeta);
});

router.get('/api/picklists/keywords/*', function (req, res) {
    utils.readJson(path.join(__dirname, '/keywords.json'), function (data) {
        res.json({
            data: _.find(data,
                function (item) {
                    return item.key === req.params[0];
                }
            )
        });
    });
});


module.exports = router;