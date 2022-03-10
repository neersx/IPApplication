describe('inprotech.configuration.general.validcombination.ValidPicklistMaintenanceController', function() {
    'use strict';

    var controller, scope, validPicklistService;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.validcombination']);
            validPicklistService = $injector.get('validPicklistServiceMock');
            $provide.value('validPicklistService', validPicklistService);
        });
    });

    beforeEach(inject(function($controller, $rootScope) {
        scope = $rootScope.$new();
        controller = function(dependencies) {
            return $controller('validPicklistMaintenanceController', angular.extend({ $scope: scope }, dependencies));
        };
    }));
    describe('initializing', function() {
        it('should initialise validCombination properties for action', function() {
            scope = {
                entityType: "action",
                state: "adding",
                model: {
                    validCombinationKeys: {
                        caseTypeModel: { key: 1 },
                        propertyTypeModel: { key: 2 },
                        jurisdictionModel: { key: 3 }
                    }
                }
            }
            spyOn(validPicklistService, 'getPropertyType').and.callThrough();
            var ctr = controller();
            ctr.init();

            expect(scope.model.caseType.key).toEqual(scope.model.validCombinationKeys.caseTypeModel.key);
            expect(scope.model.jurisdictions[0].key).toEqual(scope.model.validCombinationKeys.jurisdictionModel.key);
            expect(validPicklistService.getPropertyType).toHaveBeenCalled();
        });
        it('should initialise validCombination properties for propertyType', function() {
            scope = {
                entityType: "propertyType",
                state: "adding",
                model: {
                    validCombinationKeys: {
                        propertyTypeModel: { key: 2 },
                        jurisdictionModel: { key: 3 }
                    }
                }
            }
            spyOn(validPicklistService, 'getPropertyType').and.callThrough();
            var ctr = controller();
            ctr.init();

            expect(scope.model.jurisdictions[0].key).toEqual(scope.model.validCombinationKeys.jurisdictionModel.key);
            expect(scope.model.propertyType).toBe(undefined);
            expect(validPicklistService.getPropertyType).not.toHaveBeenCalled();
        });
        it('should initialise validCombination properties for subType', function() {
            scope = {
                entityType: "subType",
                state: "adding",
                model: {
                    validCombinationKeys: {
                        propertyTypeModel: { key: 2 },
                        jurisdictionModel: { key: 3 },
                        caseTypeModel: { key: 'P' },
                        caseCategoryModel: { key: 1, code: 'N' },
                        subTypeModel: { key: 'S' }
                    }
                }
            }
            spyOn(validPicklistService, 'getPropertyType').and.callThrough();
            spyOn(validPicklistService, 'getCaseCategory').and.callThrough();
            var ctr = controller();
            ctr.init();

            expect(scope.model.jurisdictions[0].key).toEqual(scope.model.validCombinationKeys.jurisdictionModel.key);
            expect(scope.model.subType).toBe(undefined);
            expect(validPicklistService.getPropertyType).toHaveBeenCalled();
            expect(validPicklistService.getCaseCategory).toHaveBeenCalled();
        });

        it('should not initialize validCombination properties', function() {
            scope = {
                state: "adding",
                model: {}
            }

            var ctr = controller();
            ctr.init();

            expect(scope.model).toEqual({});
        });
    });
    describe('action picklist selection change', function() {
        it('should set validDescription on selection change', function() {
            var c = controller();
            scope.entityType = 'action';
            scope.model = {
                action: {
                    key: 'A',
                    value: 'Filling'
                },
                validDescription: null
            };
            var validDescription = {
                $dirty: false
            };
            c.onPicklistSelectionChanged(validDescription);
            expect(scope.model.validDescription).toEqual(scope.model.action.value);
        });

        it('should not set validDescription on selection change if changed manually', function() {
            var c = controller();
            scope.entityType = 'action';
            scope.model = {
                action: {
                    key: 'A',
                    value: 'Filling'
                },
                validDescription: 'test'
            };
            var validDescription = {
                $dirty: true
            };
            c.onPicklistSelectionChanged(validDescription);
            expect(scope.model.validDescription).toEqual('test');
        });
    });
});
