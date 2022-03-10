describe('inprotech.configuration.rules.workflows.workflowsEntryControlStepsService', function() {
    'use strict';

    var workflowsEntryControlService, service, promiseMock;
    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            promiseMock = test.mock('promise');
            workflowsEntryControlService = test.mock('workflowsEntryControlService');
        });

        inject(function(workflowsEntryControlStepsService) {
            service = workflowsEntryControlStepsService;
        });
    });

    it('calls workflowsEntryControlStepsService get steps with correct paramaters', function() {
        workflowsEntryControlService.getSteps = promiseMock.createSpy([]);

        service.getSteps(10, 11);

        expect(workflowsEntryControlService.getSteps).toHaveBeenCalledWith(10, 11);
    });

    it('getSteps value data along with configuration data', function() {
        var step1 = {
            id: 1,
            step: {
                type: "N",
                value: "Names"
            },
            categories: [{
                categoryCode: 'nameType',
                categoryValue: {
                    key: 1,
                    code: 'I',
                    value: 'Instructor'
                }
            }, {
                categoryCode: 'numberType',
                categoryValue: {
                    key: 1
                }
            }]
        };

        workflowsEntryControlService.getSteps = promiseMock.createSpy([step1]);

        service.getSteps(10, 100).then(function(data) {
            expect(data[0].categories.length).toBe(1);
            var resultCategory = data[0].categories[0];

            expect(resultCategory.categoryName).toBe('nameType');
            expect(resultCategory.isMandatory).toBeTruthy();
        });
    });

    it('checkStepCategories sets categories applicable for the screentype selected', function() {
        var step = {
            id: 1,
            step: {
                type: "X",
                value: "NameText"
            }
        };
        service.checkStepCategories(step);
        expect(step.categories).not.toBe(null);
        expect(step.categories.length).toBe(2);
        expect(step.categories[0].categoryCode).toBe('nameType');
        expect(step.categories[0].categoryName).toBe('nameType');
        expect(step.categories[0].isMandatory).toBeTruthy();

        expect(step.categories[1].categoryCode).toBe('textType');
        expect(step.categories[1].categoryName).toBe('textType');
        expect(step.categories[1].isMandatory).toBeTruthy();
        expect(step.categories[1].query.mode).toBe('case');
    });

    it('translateStepCategory returns key with namespace', function() {
        var result = service.translateStepCategory('someCategoryName');
        expect(result).toBe('workflows.entrycontrol.steps.someCategoryName');
    });

    describe('areStepsSame', function() {
        it('returns true, if steps are same along with the mandataory categories', function() {
            var step1 = {
                id: 1,
                step: {
                    type: "N",
                    value: "Names"
                },
                categories: [{
                    categoryCode: 'nameType',
                    categoryValue: {
                        key: 1,
                        code: 'I',
                        value: 'Instructor'
                    }
                }]
            };

            var step2 = {
                id: 5,
                step: {
                    type: "N",
                    value: "Names"
                },
                categories: [{
                    categoryCode: 'nameType',
                    categoryValue: {
                        key: 1,
                        code: 'I',
                        value: 'Instructor'
                    }
                }]
            };

            var result = service.areStepsSame(step1, step2);
            expect(result).toBeTruthy();
        });

        it('returns false, if steps are different due to different mandataory categories', function() {
            var step1 = {
                id: 1,
                step: {
                    type: "N",
                    value: "Names"
                },
                categories: [{
                    categoryCode: 'nameType',
                    categoryValue: {
                        key: 1,
                        code: 'I',
                        value: 'Instructor'
                    },
                    isMandatory: true
                }]
            };

            var step2 = {
                id: 5,
                step: {
                    type: "N",
                    value: "Names"
                },
                categories: [{
                    categoryCode: 'nameType',
                    categoryValue: {
                        key: 5,
                        code: 'O',
                        value: 'Owner'
                    },
                    isMandatory: true
                }]
            };

            var result = service.areStepsSame(step1, step2);
            expect(result).toBeFalsy();
        });

        it('returns true, if step values are same and it does not have any mandatory category ', function() {
            var step1 = {
                id: 1,
                step: {
                    type: "O",
                    value: "Numbers"
                },
                categories: [{
                    categoryCode: 'numberType',
                    categoryValue: {
                        key: 1
                    },
                    isMandatory: false
                }]
            };

            var step2 = {
                id: 5,
                step: {
                    type: "O",
                    value: "Numbers"
                },
                categories: [{
                    categoryCode: 'numberType',
                    categoryValue: {
                        key: 5
                    },
                    isMandatory: false
                }]
            };

            var result = service.areStepsSame(step1, step2);
            expect(result).toBeTruthy();
        });

        it('returns false, if step values are different even if step type is same', function(){
             var step1 = {
                id: 1,
                step: {
                    type: "O",
                    value: "Numbers"
                },
                categories: [{
                    categoryCode: 'numberType',
                    categoryValue: {
                        key: 1
                    },
                    isMandatory: true
                }]
            };

            var step2 = {
                id: 5,
                step: {
                    type: "O",
                    value: "Officail Numbers"
                },
                categories: [{
                    categoryCode: 'numberType',
                    categoryValue: {
                        key: 5
                    },
                    isMandatory: true
                }]
            };

            var result = service.areStepsSame(step1, step2);
            expect(result).toBeFalsy();
        });
    });
});
