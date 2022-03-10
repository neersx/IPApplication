describe('inprotech.configuration.rules.workflows.ipWorkflowsEntryControlChangeStatus', function() {
    'use strict';

    var controller, extObjFactory, viewData;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module('inprotech.configuration.general.status');
        module(function() {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.core.extensible']);

            extObjFactory = $injector.get('ExtObjFactory');
        });
    });

    beforeEach(inject(function($rootScope, $componentController) {
        controller = function(characteristics) {
            var scope = $rootScope.$new();
            viewData = {
                canEdit: true,
                entryId: 1,
                criteriaId: 2,
                characteristics: characteristics || {},
                canAddValidCombinations: false,
                changeRenewalStatus: -10,
                changeCaseStatus: -11,
                isInherited: true,
                parent: {
                    changeCaseStatus: 'a',
                    changeRenewalStatus: 'b'
                }
            };
            var topic = {
                params: {
                    viewData: viewData
                }
            };

            return $componentController('ipWorkflowsEntryControlChangeStatus', {
                $scope: scope,
                ExtObjFactory: extObjFactory
            }, {
                topic: topic
            });
        };
    }));

    describe('initialise controller', function() {
        it('should initialise variables and objects correctly', function() {
            var c = controller();
            c.$onInit();
            expect(c.canEdit).toEqual(true);
            expect(c.formData.getRaw()).toBe(viewData);
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
            
            expect(c.parentData.changeCaseStatus).toEqual('a');
            expect(c.parentData.changeRenewalStatus).toEqual('b');
        });
    });
});