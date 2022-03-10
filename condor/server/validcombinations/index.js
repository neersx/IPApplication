'use strict';

var router = require('express').Router();
var fs = require('fs');
var path = require('path');
var utils = require('../utils');
var _ = require('underscore');

function search(data, criteria) {
    if (criteria === null) {
        return data;
    }

    var parsed = JSON.parse(criteria);

    if(parsed.jurisdictions && parsed.jurisdictions.length > 0) {
        data = _.filter(data, function(item) {
            return item.countryId && _.any(parsed.jurisdictions, function(jurisdiction){
                return jurisdiction === item.countryId;
            });
        });
    }

    if(parsed.propertyType) {
        data = _.filter(data, function(item) {
            return item.propertyTypeId && parsed.propertyType === item.propertyTypeId;
        });
    }

    if(parsed.caseType) {
        data = _.filter(data, function(item) {
            return item.caseTypeId && parsed.caseType === item.caseTypeId;
        });
    }

    if(parsed.action) {
        data = _.filter(data, function(item) {
            return item.actionId && parsed.action === item.actionId;
        });
    }

    if(parsed.caseCategory) {
        data = _.filter(data, function(item) {
            return item.caseCategoryId && parsed.caseCategory === item.caseCategoryId;
        });
    }

    if(parsed.subType) {
        data = _.filter(data, function(item) {
            return item.subTypeId && parsed.subType === item.subTypeId;
        });
    }

    if(parsed.checklist) {
        data = _.filter(data, function(item) {
            return item.checklistType && parsed.checklist === item.checklistType;
        });
    }

    if(parsed.relationship) {
        data = _.filter(data, function(item) {
            return item.relationshipCode && parsed.relationship === item.relationshipCode;
        });
    }
    
    if(parsed.status) {
        data = _.filter(data, function(item) {
            return item.statusCode && parsed.status === item.statusCode;
        });
    }

    return data;
}

router.get('/api/configuration/validcombination/viewData', function(req, res) {
    var fileStream = fs.createReadStream(path.join(__dirname, '/viewdata.json'));
    res.type('json');
    fileStream.pipe(res);
});

/* Property Type Search and Maintenance */
router.get('/api/configuration/validcombination/propertytype/search*', function(req, res) {
    utils.readJson(path.join(__dirname, './propertyTypeSearchResults.json'), function(data) {
        var filtered = search(data, req.query.criteria);
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        res.json({
            data: filtered,
            pagination: {
                total: total
            }
        });
    });
});

router.get('/api/configuration/validcombination/propertytype', function(req, res) {
    utils.readJson(path.join(__dirname, './propertyTypeMaintenance.json'), function(data) {      
        
        var validIdentifier = JSON.parse(req.query.entitykey);
        var filtered = [];
        
        if(validIdentifier) {
            filtered = _.filter(data, function(item) {
                return item.validPropertyIdentifier.countryId === validIdentifier.countryId
                        && item.validPropertyIdentifier.propertyTypeId === validIdentifier.propertyTypeId
            });
        }        
        
        res.json(_.first(filtered));
    });
});

router.put('/api/configuration/validcombination/propertytype', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {countryId: req.body.validPropertyIdentifier.countryId, propertyTypeId: req.body.validPropertyIdentifier.propertyTypeId}
        }
    });
});

router.post('/api/configuration/validcombination/propertytype', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {countryId: req.body.jurisdictions[0].code, propertyTypeId: req.body.propertyType.code}
        }
    });
});

router.post('/api/configuration/validcombination/propertytype/delete', function(req, res) {
    res.json({
       hasError: false
    });
});

/* Action Search and Maintenance */
router.get('/api/configuration/validcombination/action/search*', function(req, res) {
    utils.readJson(path.join(__dirname, './actionSearchResults.json'), function(data) {
        var filtered = search(data, req.query.criteria);
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        res.json({
            data: filtered,
            pagination: {
                total: total
            }
        });
    });
});

router.get('/api/configuration/validcombination/action', function(req, res) {
    utils.readJson(path.join(__dirname, './actionMaintenance.json'), function(data) {       
        
        var validIdentifier = JSON.parse(req.query.entitykey);
        var filtered = [];
        
        if(validIdentifier) {
            filtered = _.filter(data, function(item) {
                return item.validActionIdentifier.countryId === validIdentifier.countryId
                        && item.validActionIdentifier.propertyTypeId === validIdentifier.propertyTypeId
                        && item.validActionIdentifier.caseTypeId === validIdentifier.caseTypeId
                        && item.validActionIdentifier.actionId === validIdentifier.actionId
            });
        }        
        
        res.json(_.first(filtered));
    });
});

router.put('/api/configuration/validcombination/action', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                           countryId: req.body.validActionIdentifier.countryId,
                           propertyTypeId: req.body.validActionIdentifier.propertyTypeId,
                           caseTypeId: req.body.validActionIdentifier.caseTypeId,
                           actionId: req.body.validActionIdentifier.actionId
                         }
        }
    });
});

router.post('/api/configuration/validcombination/action', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                            countryId: req.body.jurisdictions[0].code,
                            propertyTypeId: req.body.propertyType.code,
                            caseTypeId: req.body.caseType.code,
                            actionId: req.body.action.code
                         }
        }
    });
});

router.post('/api/configuration/validcombination/action/delete', function(req, res) {
    res.json({
       hasError: false
    });
});


/* Action Order Search and Maintenance */
router.get('/api/configuration/validcombination/action/validactions', function(req, res) {
    utils.readJson(path.join(__dirname, './actionMaintenance.json'), function(data) {       
        
        var actionOrderCriteria = JSON.parse(req.query.criteria);        
        var filtered = [];
        
        if(actionOrderCriteria) {
            filtered = _.filter(data, function(item) {
                return item.validActionIdentifier.countryId === actionOrderCriteria.jurisdiction
                        && item.validActionIdentifier.propertyTypeId === actionOrderCriteria.propertyType
                        && item.validActionIdentifier.caseTypeId === actionOrderCriteria.caseType
            });
        }        
        
        var validActionsOrderResponse = {
            validActions: [],
            orderCriteria: actionOrderCriteria
        }
        
        _.each(filtered, function(validAction) {
            validActionsOrderResponse.validActions.push(validAction.validActionOrder);
        });
        
        res.json(validActionsOrderResponse);
    });
});

router.post('/api/configuration/validcombination/action/updateactionsequence', function(req, res) {
    res.json({
        result: {
            result: 'success'
        }
    });
});


/* Copy valid combination */
router.get('/api/configuration/validcombination/validatecopy', function(req, res) {
    res.json({
        result: null
    });
});

router.post('/api/configuration/validcombination/copy', function(req, res) {
    res.json({
        result: {
            result: "success"
        }
    });
});

/* SubType Search and Maintenance */
router.get('/api/configuration/validcombination/subtype/search*', function(req, res) {
    utils.readJson(path.join(__dirname, './subTypeSearchResults.json'), function(data) {
        var filtered = search(data, req.query.criteria);
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        res.json({
            data: filtered,
            pagination: {
                total: total
            }
        });
    });
});

router.get('/api/configuration/validcombination/subtype', function(req, res) {
    utils.readJson(path.join(__dirname, './subTypeMaintenance.json'), function(data) {       
        
        var validIdentifier = JSON.parse(req.query.entitykey);
        var filtered = [];
        
        if(validIdentifier) {
            filtered = _.filter(data, function(item) {
                return item.validSubTypeIdentifier.countryId === validIdentifier.countryId
                        && item.validSubTypeIdentifier.propertyTypeId === validIdentifier.propertyTypeId
                        && item.validSubTypeIdentifier.caseTypeId === validIdentifier.caseTypeId
                        && item.validSubTypeIdentifier.subTypeId === validIdentifier.subTypeId
                        && item.validSubTypeIdentifier.caseCategoryId === validIdentifier.caseCategoryId
            });
        }        
        
        res.json(_.first(filtered));
    });
});

router.put('/api/configuration/validcombination/subtype', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                           countryId: req.body.validSubTypeIdentifier.countryId,
                           propertyTypeId: req.body.validSubTypeIdentifier.propertyTypeId,
                           caseTypeId: req.body.validSubTypeIdentifier.caseTypeId,
                           subTypeId: req.body.validSubTypeIdentifier.subTypeId,
                           caseCategoryId: req.body.validSubTypeIdentifier.caseCategoryId
                         }
        }
    });
});

router.post('/api/configuration/validcombination/subtype', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                            countryId: req.body.jurisdictions[0].code,
                            propertyTypeId: req.body.propertyType.code,
                            caseTypeId: req.body.caseType.code,
                            subTypeId: req.body.subType.code,
                            caseCategoryId: req.body.caseCategory.code
                         }
        }
    });
});

router.post('/api/configuration/validcombination/subtype/delete', function(req, res) {
    res.json({
       hasError: false
    });
});

/* Basis Search and Maintenance */
router.get('/api/configuration/validcombination/basis/search*', function(req, res) {
    utils.readJson(path.join(__dirname, './basisSearchResults.json'), function(data) {
        var filtered = search(data, req.query.criteria);
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        res.json({
            data: filtered,
            pagination: {
                total: total
            }
        });
    });
});

router.get('/api/configuration/validcombination/basis', function(req, res) {
    utils.readJson(path.join(__dirname, './basisMaintenance.json'), function(data) {       
        
        var validIdentifier = JSON.parse(req.query.entitykey);
        var filtered = [];
        
        if(validIdentifier) {
            filtered = _.filter(data, function(item) {
                return item.validBasisIdentifier.countryId === validIdentifier.countryId
                        && item.validBasisIdentifier.propertyTypeId === validIdentifier.propertyTypeId
                        && item.validBasisIdentifier.caseTypeId === validIdentifier.caseTypeId
                        && item.validBasisIdentifier.basisId === validIdentifier.basisId
                        && item.validBasisIdentifier.caseCategoryId === validIdentifier.caseCategoryId
            });
        }        
        
        res.json(_.first(filtered));
    });
});

router.put('/api/configuration/validcombination/basis', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                           countryId: req.body.validBasisIdentifier.countryId,
                           propertyTypeId: req.body.validBasisIdentifier.propertyTypeId,
                           caseTypeId: req.body.validBasisIdentifier.caseTypeId,
                           basis: req.body.validBasisIdentifier.basisId,
                           caseCategoryId: req.body.validBasisIdentifier.caseCategoryId
                         }
        }
    });
});

router.post('/api/configuration/validcombination/basis', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                            countryId: req.body.jurisdictions[0].code,
                            propertyTypeId: req.body.propertyType.code,
                            caseTypeId: req.body.caseType.code,
                            basisId: req.body.basis.code,
                            caseCategoryId: req.body.caseCategory.code
                         }
        }
    });
});

router.post('/api/configuration/validcombination/basis/delete', function(req, res) {
    res.json({
       hasError: false
    });
});

/* Category Search and Maintenance */
router.get('/api/configuration/validcombination/category/search*', function(req, res) {
    utils.readJson(path.join(__dirname, './categorySearchResults.json'), function(data) {
        var filtered = search(data, req.query.criteria);
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        res.json({
            data: filtered,
            pagination: {
                total: total
            }
        });
    });
});

router.get('/api/configuration/validcombination/category', function(req, res) {
    utils.readJson(path.join(__dirname, './categoryMaintenance.json'), function(data) {       
        
        var validIdentifier = JSON.parse(req.query.entitykey);
        var filtered = [];
        
        if(validIdentifier) {
            filtered = _.filter(data, function(item) {
                return item.validCategoryIdentifier.countryId === validIdentifier.countryId
                        && item.validCategoryIdentifier.propertyTypeId === validIdentifier.propertyTypeId
                        && item.validCategoryIdentifier.caseTypeId === validIdentifier.caseTypeId                        
                        && item.validCategoryIdentifier.caseCategoryId === validIdentifier.caseCategoryId
            });
        }        
        
        res.json(_.first(filtered));
    });
});

router.put('/api/configuration/validcombination/category', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                           countryId: req.body.validCategoryIdentifier.countryId,
                           propertyTypeId: req.body.validCategoryIdentifier.propertyTypeId,
                           caseTypeId: req.body.validCategoryIdentifier.caseTypeId,                           
                           caseCategoryId: req.body.validCategoryIdentifier.caseCategoryId
                         }
        }
    });
});

router.post('/api/configuration/validcombination/category', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                            countryId: req.body.jurisdictions[0].code,
                            propertyTypeId: req.body.propertyType.code,
                            caseTypeId: req.body.caseType.code,                            
                            caseCategoryId: req.body.caseCategory.code
                         }
        }
    });
});

router.post('/api/configuration/validcombination/category/delete', function(req, res) {
    res.json({
       hasError: false
    });
});

/* Checklist Search and Maintenance */
router.get('/api/configuration/validcombination/checklist/search*', function(req, res) {
    utils.readJson(path.join(__dirname, './checklistSearchResults.json'), function(data) {
        var filtered = search(data, req.query.criteria);
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        res.json({
            data: filtered,
            pagination: {
                total: total
            }
        });
    });
});

router.get('/api/configuration/validcombination/checklist', function(req, res) {
    utils.readJson(path.join(__dirname, './checklistMaintenance.json'), function(data) {       
        
        var validIdentifier = JSON.parse(req.query.entitykey);
        var filtered = [];
        
        if(validIdentifier) {
            filtered = _.filter(data, function(item) {
                return item.validChecklistIdentifier.countryId === validIdentifier.countryId
                        && item.validChecklistIdentifier.propertyTypeId === validIdentifier.propertyTypeId
                        && item.validChecklistIdentifier.caseTypeId === validIdentifier.caseTypeId                        
                        && item.validChecklistIdentifier.checklistId === validIdentifier.checklistId
            });
        }        
        
        res.json(_.first(filtered));
    });
});

router.put('/api/configuration/validcombination/checklist', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                           countryId: req.body.validChecklistIdentifier.countryId,
                           propertyTypeId: req.body.validChecklistIdentifier.propertyTypeId,
                           caseTypeId: req.body.validChecklistIdentifier.caseTypeId,                           
                           checklistId: req.body.validChecklistIdentifier.checklistId
                         }
        }
    });
});

router.post('/api/configuration/validcombination/checklist', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                            countryId: req.body.jurisdictions[0].code,
                            propertyTypeId: req.body.propertyType.code,
                            caseTypeId: req.body.caseType.code,                            
                            checklistId: req.body.checklist.code
                         }
        }
    });
});

router.post('/api/configuration/validcombination/checklist/delete', function(req, res) {
    res.json({
       hasError: false
    });
});

/* Relationship Search and Maintenance */
router.get('/api/configuration/validcombination/relationship/search*', function(req, res) {
    utils.readJson(path.join(__dirname, './relationshipSearchResults.json'), function(data) {
        var filtered = search(data, req.query.criteria);
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        res.json({
            data: filtered,
            pagination: {
                total: total
            }
        });
    });
});

router.get('/api/configuration/validcombination/relationship', function(req, res) {
    utils.readJson(path.join(__dirname, './relationshipMaintenance.json'), function(data) {       
        
        var validIdentifier = JSON.parse(req.query.entitykey);
        var filtered = [];
        
        if(validIdentifier) {
            filtered = _.filter(data, function(item) {
                return item.validRelationshipIdentifier.countryId === validIdentifier.countryId
                        && item.validRelationshipIdentifier.propertyTypeId === validIdentifier.propertyTypeId
                        && item.validRelationshipIdentifier.relationshipCode === validIdentifier.relationshipCode
            });
        }        
        
        res.json(_.first(filtered));
    });
});

router.put('/api/configuration/validcombination/relationship', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                           countryId: req.body.validRelationshipIdentifier.countryId,
                           propertyTypeId: req.body.validRelationshipIdentifier.propertyTypeId,
                           relationshipCode: req.body.validRelationshipIdentifier.relationshipCode
                         }
        }
    });
});

router.post('/api/configuration/validcombination/relationship', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                            countryId: req.body.jurisdictions[0].code,
                            propertyTypeId: req.body.propertyType.code,
                            relationshipCode: req.body.relationship.code
                         }
        }
    });
});

router.post('/api/configuration/validcombination/relationship/delete', function(req, res) {
    res.json({
       hasError: false
    });
});

/* Jurisdiction Search */
router.get('/api/configuration/validcombination/jurisdiction/search*', function(req, res) {
    utils.readJson(path.join(__dirname, './jurisdictionSearchResults.json'), function(data) {
        var filtered = search(data, req.query.criteria);
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        res.json({
            data: filtered,
            pagination: {
                total: total
            }
        });
    });
});


/* Status Search and Maintenance */
router.get('/api/configuration/validcombination/status/search*', function(req, res) {
    utils.readJson(path.join(__dirname, './statusSearchResults.json'), function(data) {
        var filtered = search(data, req.query.criteria);
        var total = filtered.length;
        filtered = utils.sortAndPaginate(filtered, req.query.params);
        res.json({
            data: filtered,
            pagination: {
                total: total
            }
        });
    });
});

router.get('/api/configuration/validcombination/status', function(req, res) {
    utils.readJson(path.join(__dirname, './statusMaintenance.json'), function(data) {       
        
        var validIdentifier = JSON.parse(req.query.entitykey);
        var filtered = [];
        
        if(validIdentifier) {
            filtered = _.filter(data, function(item) {
                return item.validStatusIdentifier.countryId === validIdentifier.countryId
                        && item.validStatusIdentifier.propertyTypeId === validIdentifier.propertyTypeId
                        && item.validStatusIdentifier.caseTypeId === validIdentifier.caseTypeId
                        && item.validStatusIdentifier.statusCode === validIdentifier.statusCode
            });
        }        
        
        res.json(_.first(filtered));
    });
});

router.put('/api/configuration/validcombination/status', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                           countryId: req.body.validStatusIdentifier.countryId,
                           propertyTypeId: req.body.validStatusIdentifier.propertyTypeId,
                           caseTypeId: req.body.validStatusIdentifier.caseTypeId,
                           statusCode: req.body.validStatusIdentifier.statusCode
                         }
        }
    });
});

router.post('/api/configuration/validcombination/status', function(req, res) {    
    res.json({
        result: {
            result: 'success',
            updatedKeys: {
                            countryId: req.body.jurisdictions[0].code,
                            propertyTypeId: req.body.propertyType.code,
                            caseTypeId: req.body.caseType.code,
                            statusCode: req.body.status.key
                         }
        }
    });
});

router.post('/api/configuration/validcombination/status/delete', function(req, res) {
    res.json({
       hasError: false
    });
});

module.exports = router;
