'use strict';

var router = require('express').Router();
var path = require('path');
var utils = require('../utils');
var _ = require('underscore');

router.get('/api/case/:caseKey/searchsummary', function(req, res) {
    utils.readJson(path.join(__dirname, './caseSummary.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/case/:caseKey/overview', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-details.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/case/screencontrol/:criteriaKey', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-screencontrol.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/case/:caseKey/ipp-availability', function(req, res) {
    res.json({
        file: {
            isEnabled: true,
            hasViewAccess: true
        }
    });
});

router.get('/api/case/:caseKey/support-email', function(req, res) {
    res.json({
        uri: 'mailto:someone@cpaglobal.com?subject=some-case&body=some-body'
    });
});

router.get('/api/case/action/view', function(req, res) {
    utils.readJson(path.join(__dirname, './importance-level.json'), function(data) {
        res.json({
            canMaintainWorkflow: true,
            importanceLevel: 5,
            importanceLevelOptions: data,
            requireImportanceLevel: false
        });
    });

});

router.get('/api/case/:caseKey/action', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-action.json'), function(data) {
        var paged = utils.sortAndPaginate(data, req.query.params);
        res.json({
            data: paged,
            pagination: {
                total: data.length
            }
        });
    });
});

router.get('/api/case/:caseKey/action/:actionId', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-action-event.json'), function(data) {
        var paged = utils.sortAndPaginate(data, req.query.params);
        res.json({
            data: paged,
            pagination: {
                total: data.length
            }
        });
    });
});

router.get('/api/case/:caseKey/names', function(req, res) {
    var nameTypeFilters = JSON.parse(req.query.nameTypes).keys || [];
    if (nameTypeFilters.length == 1 && nameTypeFilters[0] === '') nameTypeFilters = [];
    utils.readJson(path.join(__dirname, './caseview-names.json'), function(data) {
        if (nameTypeFilters.length > 0) {
            data = _.filter(data, function(item) {
                return _.any(nameTypeFilters, function(nt) {
                    return item.typeId === nt
                });
            });
        }

        res.json({
            data: data,
            pagination: {
                total: data.length
            }
        });
    });
});

router.get('/api/case/:caseKey/names/email-template', function(req, res) {
    res.json([{
        recipientEmail: 'gg@maxim.yarrow.colman.com',
        recipientCopiesTo: ['someone@myorg.com', 'someone.else@myorg.com'],
        subject: 'Regarding XXXX',
        body: 'Regarding XXXX\nMethod to improve productivity'
    }]);
});

router.get('/api/case/:caseId/critical-dates', function(req, res) {
    utils.readJson(path.join(__dirname, '/critical-dates.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/case/:caseId/caseviewevent/occurred', function(req, res) {
    utils.readJson(path.join(__dirname, '/caseview-events.json'), function(data) {
        data = _.filter(data, function(item) {
            return item.isOccurred;
        });
        var paged = utils.sortAndPaginate(data, req.query.params);
        res.json({
            data: paged,
            pagination: {
                total: data.length
            }
        });
    });
});

router.get('/api/case/:caseId/caseviewevent/due', function(req, res) {
    utils.readJson(path.join(__dirname, '/caseview-events.json'), function(data) {
        data = _.filter(data, function(item) {
            return !item.isOccurred;
        });
        var paged = utils.sortAndPaginate(data, req.query.params);
        res.json({
            data: paged,
            pagination: {
                total: data.length
            }
        });
    });
});

router.get('/api/case/:caseId/relatedcases', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-relatedcases.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/case/importanceLevelsNoteTypes', function(req, res) {
    res.json({
        importanceLevel: 5,
        importanceLevelOptions: [{
            code: 9,
            description: "Critical"
        }, {
            code: 8,
            description: "Very Important"
        }, {
            code: 7,
            description: "Important"
        }, {
            code: 5,
            description: "Normal"
        }, {
            code: 3,
            description: "Internal low level"
        }, {
            code: 1,
            description: "Minimal"
        }],
        requireImportanceLevel: false
    });
});

router.get('/api/case/caseview', function(req, res) {
    res.json({
        canViewOtherNumbers: true,
        displayRichTextFormat: true,
        keepSpecHistory: false
    });
});

router.get('/api/case/:caseId/officialnumbers/ipoffice', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-officialnumbers.json'), function(data) {
        res.json(_.filter(data, function(item) {
            return item.ipOffice;
        }));
    });
});

router.get('/api/case/:caseId/officialnumbers/other', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-officialnumbers.json'), function(data) {
        res.json(_.filter(data, function(item) {
            return item.ipOffice === false;
        }));
    });
});

router.get('/api/case/:caseId/texts', function(req, res) {
    var textTypes = JSON.parse(req.query.textTypes);
    var fileName = './caseview-texts.json';
    if (textTypes.keys.indexOf('A') > -1) {
        fileName = './caseview-texts.single.json'
    }
    if (textTypes.keys.indexOf('CL') > -1) {
        fileName = './caseview-texts.multi.json'
    }
    utils.readJson(path.join(__dirname, fileName), function(data) {
        var paged = utils.sortAndPaginate(data, req.query.params);
        res.json({
            data: paged,
            pagination: {
                total: data.length
            }
        });
    });
});

router.get('/api/case/:caseId/textHistory', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-textshistory.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/case/:caseId/images', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-images.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/case/image/:caseId', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-image.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/case/:caseId/designatedjurisdiction', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-designatedjurisdiction.json'), function(data) {
        data = utils.filterGridResults(data, req.query.params);
        var paged = utils.sortAndPaginate(data, req.query.params);
        res.json({
            data: paged,
            pagination: {
                total: data.length
            }
        });
    });
});

router.get('/api/case/:caseId/designatedjurisdiction/filterData/:column', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-designatedjurisdiction.json'), function(data) {
        data = utils.readColumnFilter(data, req.params.column, req.query.columnFilters);
        res.json(data);
    });
});

router.get('/api/case/:caseKey/designationdetails', function(req, res) {
    utils.readJson(path.join(__dirname, './designated-summary.json'), function(data) {
        var filteredData = _.find(data, function(item) {
            return item.caseKey == req.params.caseKey;
        });

        res.json(filteredData);
    });
});

router.get('/api/case/:caseKey/weblinks', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-weblinks.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/case/:caseKey/efiling', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-efiling.json'), function(data) {
        var paged = utils.sortAndPaginate(data, req.query.params);
        res.json({
            data: paged,
            pagination: {
                total: data.length
            }
        });
    });
});

router.get('/api/case/:caseKey/efilinghistory', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-efilinghistory.json'), function(data) {
        var paged = utils.sortAndPaginate(data, req.query.params);
        res.json({
            data: paged,
            pagination: {
                total: data.length
            }
        });
    });
});

router.get('/api/case/:caseKey/efilingPackageFiles', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-efilingpackagefiles.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/case/:caseId/renewals/:screenCriteriaKey', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-renewals.json'), function(data) {
        res.json(data);
    });
});

router.get('/api/case/program*', function(req, res) {
    res.json();
});

router.get('/api/case/:caseId/standingInstructions', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-standing-instructions.json'), function(data) {
        res.json(data);
    });
});
router.get('/api/case/:caseId/internalDetails', function(req, res) {
    utils.readJson(path.join(__dirname, './caseview-internaldetails.json'), function(data) {
        res.json(data);
    });
});

module.exports = router;