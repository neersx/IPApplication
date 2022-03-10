angular.module('inprotech.configuration.rules.workflows').factory('workflowsEntryControlStepsService', function(workflowsEntryControlService) {
    'use strict';

    var stepCategoryPrefix = 'workflows.entrycontrol.steps.';
    var stepCategories = {
        'A': {
            categories: [{
                categoryCode: 'action',
                categoryName: 'createAction',
                isMandatory: true
            }]
        },
        'C': {
            categories: [{
                categoryCode: 'checklist',
                categoryName: 'checklistTypes',
                isMandatory: true
            }]
        },
        'F': {
            categories: [{
                categoryCode: 'designationStage',
                categoryName: 'designationStage',
                isMandatory: false
            }]
        },
        'G': {
            categories: []
        },
        'M': {
            categories: [{
                categoryCode: 'relationship',
                categoryName: 'mandatoryRelationship',
                isMandatory: false
            }]
        },
        'N': {
            categories: [{
                categoryCode: 'nameType',
                categoryName: 'nameType',
                isMandatory: true
            }]
        },
        'O': {
            categories: [{
                categoryCode: 'numberType',
                categoryName: 'officialNumber',
                isMandatory: false
            }]
        },
        'P': {
            categories: [{
                categoryCode: 'nameTypeGroup',
                categoryName: 'nameTypeGroup',
                isMandatory: true
            }]
        },
        'R': {
            categories: [{
                categoryCode: 'relationship',
                categoryName: 'relationship',
                isMandatory: true
            }]
        },
        'T': {
            categories: [{
                categoryCode: 'textType',
                categoryName: 'textType',
                query: {
                    mode: 'case'
                },
                isMandatory: true
            }]
        },
        'X': {
            categories: [{
                categoryCode: 'nameType',
                categoryName: 'nameType',
                isMandatory: true
            }, {
                categoryCode: 'textType',
                categoryName: 'textType',
                query: {
                    mode: 'case'
                },
                isMandatory: true
            }]
        }
    };

    function translateStepCategory(categoryName) {
        return stepCategoryPrefix + categoryName;
    }

    function stepCategoryDisplay(category){
        if (!category || !category.categoryValue)
            return null;
            
        return category.categoryValue.displayValue || category.categoryValue.value;
    }

    function getFiltersForStep(stepType) {
        if (stepType == null) {
            stepType = 'G';
        }

        stepType = stepType.trim();

        return stepCategories[stepType].categories;
    }

    function anyMandatoryCategories(item) {
        return _.any(item.categories, {
            isMandatory: true
        });
    }

    function getSteps(criteriaId, entryId) {
        return workflowsEntryControlService.getSteps(criteriaId, entryId).then(function(data) {
            _.each(data, function(d) {
                checkStepCategories(d);
            });
            return data;
        });
    }

    function checkStepCategories(stepDetails) {
        var expectedFilters = stepDetails.step ? getFiltersForStep(stepDetails.step.type) : [];
        var expectedFilterCodes = stepDetails.step ? _.pluck(expectedFilters, 'categoryCode') : [];

        stepDetails.categories = _.filter(stepDetails.categories, function(c) {
            return _.contains(expectedFilterCodes, c.categoryCode);
        });

        _.each(expectedFilters, function(ef) {
            var correspondingCategory = _.findWhere(stepDetails.categories, {
                categoryCode: ef.categoryCode
            });
            if (correspondingCategory) {
                _.extend(correspondingCategory, ef);
            } else {
                stepDetails.categories.push(angular.copy(ef));
            }
        });
    }

    function areStepsSame(step1, step2) {
        var result = false;
        if (step1.step.value === step2.step.value) {
            //If no manadatory filter, the step type can be added only once
            if (!anyMandatoryCategories(step1)) {
                return true;
            }

            //All mandatory fields are same - then treat as duplicate
            result = _.every(_.where(step1.categories, {
                isMandatory: true
            }), function(c) {
                var correspondingCategory = _.findWhere(step2.categories, {
                    categoryCode: c.categoryCode
                });

                if (correspondingCategory) {
                    if (c.categoryValue && correspondingCategory.categoryValue) {
                        return c.categoryValue.key === correspondingCategory.categoryValue.key;
                    } else {
                        return !(c.categoryValue || correspondingCategory.categoryValue);
                    }
                }
            });

            return result;
        }

        return false;
    }

    var service = {
        translateStepCategory: translateStepCategory,
        categoryDisplay: stepCategoryDisplay,
        getSteps: getSteps,
        checkStepCategories: checkStepCategories,
        areStepsSame: areStepsSame
    };

    return service;
});
