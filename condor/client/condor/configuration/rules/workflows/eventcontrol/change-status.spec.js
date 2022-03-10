describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlChangeStatus', function() {
    'use strict';

    var controller, service;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module('inprotech.mocks.configuration.rules.workflows');
        module('inprotech.configuration.general.status');
        module(function() {
            service = test.mock('workflowStatusService');
        });
    });

    beforeEach(inject(function($rootScope, $componentController) {
        controller = function() {
            var scope = $rootScope.$new();
            var topic = {
                params: {
                    viewData: {
                        canEdit: true,
                        isRenewalStatusSupported: true,
                        changeStatus: {
                            key: -333,
                            value: 'ABC'
                        },
                        changeRenewalStatus: {
                            key: -444,
                            value: 'DEF'
                        },
                        userDefinedStatus: 'adsk',
                        characteristics: 'characteristics',
                        canAddValidCombinations: false,
                        isInherited: true,
                        parent: {
                            changeStatus: 'abc',
                            changeRenewalStatus: 'def'
                        }
                    }
                }
            };
            var c = $componentController('ipWorkflowsEventControlChangeStatus', {
                $scope: scope
            }, {
                topic: topic
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialise controller', function() {
        it('should initialise variables correctly', function() {
            var c = controller();

            expect(c.changeStatus.key).toEqual(-333);
            expect(c.changeStatus.value).toEqual("ABC");
            expect(c.changeRenewalStatus.key).toEqual(-444);
            expect(c.changeRenewalStatus.value).toEqual("DEF");
            expect(c.canEdit).toEqual(true);
            expect(c.enableRenewalStatus).toEqual(true);
            expect(service).toHaveBeenCalledWith('characteristics');
            expect(c.caseStatusScope.canAddValidCombinations).toEqual(false);
            expect(c.renewalStatusScope.canAddValidCombinations).toEqual(false);
            expect(c.caseStatusScope.extendQuery).toEqual(jasmine.any(Function));
            expect(c.renewalStatusScope.extendQuery).toEqual(jasmine.any(Function));
            expect(c.caseStatusScope.filterByCriteria).toEqual(true);
            expect(c.renewalStatusScope.filterByCriteria).toEqual(true);
            expect(c.caseStatusScope.validCombination).toEqual(jasmine.any(Object));
            expect(c.renewalStatusScope.validCombination).toEqual(jasmine.any(Object));
            expect(c.changedStatus).toEqual(jasmine.any(Function));
            expect(c.caseStatusScope.add).toEqual(jasmine.any(Function));
            expect(c.renewalStatusScope.add).toEqual(jasmine.any(Function));
            expect(c.parentData.changeStatus).toEqual('abc');
            expect(c.parentData.changeRenewalStatus).toEqual('def');
        });

    });

    describe('getFormData', function() {
        it('gets case status key and renewal status key', function() {
            var c = controller();

            var formData = c.topic.getFormData();

            expect(formData).toEqual({
                changeStatusId: -333,
                changeRenewalStatusId: -444,
                userDefinedStatus: 'adsk'
            });
        });
    });
    describe('hasError', function() {
        it('returns form valid state', function() {
            var c = controller();
            c.form = {
                $invalid: true
            }
            expect(c.topic.hasError()).toBe(true);
        });
    });
    describe('isDirty', function() {
        it('returns form dirty state', function() {
            var c = controller();
            c.form = {
                $dirty: true
            }
        });
    });
});