describe('inprotech.configuration.general.validcombination.validSubTypeMaintenanceController', function() {
    'use strict';

    var controller, scope, service;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.validcombination']);
            $provide.value('validCombinationService', $injector.get('ValidCombinationServiceMock'));
        });
    });

    beforeEach(inject(function($controller, $rootScope, validCombinationService) {
        scope = $rootScope.$new();
        scope.model = {};
        scope.picklistErrors = {};
        scope.state = 'adding';
        scope.searchCriteria = {
            propertyType: {
                key: 'P',
                value: 'Patents'
            },
            caseType: {
                key: 'P',
                value: 'Properties'
            },
            caseCategory: {
                key: 'N',
                value: 'Normal'
            },
            jurisdictions: [{
                key: 'AU',
                value: 'Australia'
            }],
            subType: {
                key: 'S',
                value: 'SubType'
            }
        };
        service = validCombinationService;

        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: scope,
                validcombinationService: service
            }, dependencies);
            var c = $controller('validSubTypeMaintenanceController', dependencies);
            c.$onInit();
            return c;
        };
    }));
    describe('pre populate search criteria', function() {
        it('should set prepopulate entity from search criteria', function() {
            scope.src = 'validcombination';
            controller();
            expect(scope.model.propertyType).toBe(scope.searchCriteria.propertyType);
            expect(scope.model.caseType).toBe(scope.searchCriteria.caseType);
            expect(scope.model.jurisdictions).toBe(scope.searchCriteria.jurisdictions);
            expect(scope.model.caseCategory).toBe(scope.searchCriteria.caseCategory);
            expect(scope.model.subType).toBe(scope.searchCriteria.subType);
            expect(scope.model.validDescription).toBe(scope.searchCriteria.subType.value);
        });
        it('should set prepopulate variable to true when prepopulated from search criteria', function() {
            scope.src = 'validcombination';
            controller();
            expect(scope.model.prepopulated).toBe(true);
        });
    });
    describe('case type picklist selection change', function() {
        it('should call validateCategory if caseCategory has valid value', function() {
            scope.model = {
                caseType: {
                    key: 'P',
                    value: 'Properties'
                },
                caseCategory: {
                    key: 'N',
                    code: 'N',
                    value: 'Normal'
                }
            };
            scope.maintenance = {
                caseType: {
                    $invalid: false
                },
                caseCategory: {
                    $setValidity: jasmine.createSpy()
                }
            };
            service.validateCategory.returnValue = {
                isValid: true,
                key: 'N',
                value: 'Normal updated'
            };
            var c = controller();
            c.onCaseTypeSelectionChanged();
            expect(scope.maintenance.caseCategory.$setValidity).toHaveBeenCalledWith('invalidcombination', true);
            expect(scope.model.caseCategory.value).toBe(service.validateCategory.returnValue.value);
        });
        it('should set error if caseCategory has inValid value corresponding to caseType', function() {
            scope.model = {
                caseType: {
                    key: 'P',
                    value: 'Properties'
                },
                caseCategory: {
                    key: 'N',
                    value: 'Normal'
                }
            };
            scope.maintenance = {
                caseType: {
                    $invalid: false
                },
                caseCategory: {
                    $setValidity: jasmine.createSpy()
                }
            };
            service.validateCategory.returnValue = {
                isValid: false,
                key: null,
                value: null
            };
            var c = controller();
            c.onCaseTypeSelectionChanged();
            expect(scope.maintenance.caseCategory.$setValidity).toHaveBeenCalledWith('invalidcombination', false);
        });
    });
    describe('disable category picklist ', function() {
        it('should return true if case type is empty ', function() {


            scope.model = {};
            scope.model.caseTypeForm = {
                caseType: {
                    $invalid: false
                }
            };
            var c = controller();
            var isDisabled = c.disableCategoryPicklist();
            expect(isDisabled).toBe(true);

            scope.model = {
                caseType: null
            };

            isDisabled = c.disableCategoryPicklist();
            expect(isDisabled).toBe(true);
        });
        it('should return true if case type has invalid value', function() {
            scope.model = {
                caseType: {
                    value: 'aaa'
                },
                caseCategory: {
                    key: 'N',
                    value: 'Normal'
                }
            };
            scope.maintenance = {
                caseType: {
                    $invalid: true
                },
                caseCategory: {
                    $resetErrors: jasmine.createSpy()
                }
            };
            var c = controller();
            var isDisabled = c.disableCategoryPicklist();
            expect(isDisabled).toBe(true);
            expect(scope.model.caseCategory).toBe(null);

        });
        it('should return false if case type has value', function() {
            scope.model = {
                caseType: {
                    key: 'P',
                    value: 'Properties'
                }
            };
            scope.maintenance = {
                caseType: {
                    $invalid: false
                },
                caseCategory: {
                    $resetErrors: jasmine.createSpy()
                }
            };
            var c = controller();
            var isDisabled = c.disableCategoryPicklist();
            expect(isDisabled).toBe(false);
        });
    });
    describe('sub type picklist selection change', function() {
        it('should set valid description', function() {


            scope.model = {
                subType: {
                    key: 'M',
                    value: 'Multipart'
                },
                validDescription: null
            };

            var validDescription = {
                $dirty: false
            };
            var c = controller();
            c.onSubTypeSelectionChanged(validDescription);

            expect(scope.model.validDescription).toBe('Multipart');
        });
        it('should not set valid description if dirty', function() {
            scope.model = {
                subType: {
                    key: 'M',
                    value: 'Multipart'
                },
                validDescription: 'valid subtype'
            };

            var validDescription = {
                $dirty: true
            };

            var c = controller();

            c.onSubTypeSelectionChanged(validDescription);

            expect(scope.model.validDescription).toBe('valid subtype');
        });
    });
});