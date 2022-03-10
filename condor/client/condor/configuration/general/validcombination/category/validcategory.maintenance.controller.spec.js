describe('inprotech.configuration.general.validcombination.validCategoryMaintenanceController', function() {
    'use strict';

    var controller, scope, service, http;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.validcombination']);
            $provide.value('validCombinationService', $injector.get('ValidCombinationServiceMock'));
        });
    });

    beforeEach(inject(function($controller, $rootScope, validCombinationService, $httpBackend) {
        http = $httpBackend;
        scope = $rootScope.$new();
        scope.model = {};
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
            jurisdictions: [{
                key: 'AU',
                value: 'Australia'
            }],
            caseCategory: {
                key: 'N',
                value: 'Normal'
            }
        };
        scope.picklistErrors = {};
        service = validCombinationService;

        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: scope,
                validcombinationService: service
            }, dependencies);
            return $controller('validCategoryMaintenanceController', dependencies);
        };
    }));
    describe('pre populate search criteria', function() {
        it('should set prepopulate model from search criteria', function() {
            scope.src = 'validcombination';

            controller();

            expect(scope.model.propertyType).toBe(scope.searchCriteria.propertyType);
            expect(scope.model.caseType).toBe(scope.searchCriteria.caseType);
            expect(scope.model.jurisdictions).toBe(scope.searchCriteria.jurisdictions);
            expect(scope.model.caseCategory).toBe(scope.searchCriteria.caseCategory);
            expect(scope.model.validDescription).toBe(scope.searchCriteria.caseCategory.value);
        });
        it('should set prepopulate variable to true when prepopulated from search criteria', function() {
            scope.src = 'validcombination';
            controller();
            expect(scope.model.prepopulated).toBe(true);
        });
    });
    describe('case type picklist selection change', function() {
        it('should call validateCategory if caseCategory has valid key value', function() {
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
                caseCategory: {
                    $setValidity: jasmine.createSpy()
                },
                caseType: {
                    $invalid: false
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
                isValid: false,
                key: null,
                value: null
            };

            var c = controller();

            c.onCaseTypeSelectionChanged();
            expect(scope.maintenance.caseCategory.$setValidity).toHaveBeenCalledWith('invalidcombination', false);
        });
    });
    describe('category type picklist selection change', function() {
        it('should set valid value', function() {
            scope.model = {
                caseType: {
                    key: 'P',
                    value: 'Properties'
                },
                caseCategory: {
                    key: 'N',
                    code: 'N',
                    value: 'Normal'
                },
                validDescription: null
            };
            scope.maintenance = {
                caseCategory: {
                    $setValidity: jasmine.createSpy()
                }
            };

            var validDescription = {
                $dirty: false
            };

            var c = controller();

            c.onCaseCategorySelectionChanged(validDescription);

            expect(scope.model.validDescription).toBe('Normal');
        });
        it('should not set valid description if dirty', function() {
            scope.model = {
                caseType: {
                    key: 'P',
                    code: 'P',
                    value: 'Properties'
                },
                caseCategory: {
                    key: 'N',
                    value: 'Normal'
                },
                validDescription: 'valid'
            };

            scope.maintenance = {
                caseCategory: {
                    $setValidity: jasmine.createSpy()
                }
            };

            var validDescription = {
                $dirty: true
            };

            var c = controller();

            c.onCaseCategorySelectionChanged(validDescription);

            expect(scope.model.validDescription).toBe('valid');
        });
    });
    describe('disable category picklist ', function() {
        it('should return true if case type is empty ', function() {
            scope.model = {};
            scope.maintenance = {
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
                },
                validDescription: 'Normal'
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
            expect(scope.model.validDescription).toBe(null);
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
    describe('disable or enable Multi Class Application Allowed checkbox', function() {
        it('should disable multi class application allowed checkbox when jurisdictions have this attribute set', function() {
            scope.src = 'validcombination';
            scope.searchCriteria = {};
            scope.model.jurisdictions = [{
                key: 'AU',
                value: 'Australia'
            }];

            var multiClassJurisdictions = ['AU', 'AF', 'AD', 'AG'];
            http.whenGET('api/picklists/caseCategories/multiclasscountries')
                .respond(function() {
                    return [200, multiClassJurisdictions, {}];
                });

            var c = controller();
            http.flush();

            var result = c.allJurisdictionsMultiClass();

            expect(result).toBe(true);
        });
        it('should enable multi class application allowed checkbox when any of jurisdictions does not have this attribute set', function() {
            scope.src = 'validcombination';
            scope.searchCriteria = {};
            scope.model.jurisdictions = [{
                key: 'AF',
                value: 'Afghanistan'
            }];

            var multiClassJurisdictions = ['AU', 'AD', 'AG'];
            http.whenGET('api/picklists/caseCategories/multiclasscountries')
                .respond(function() {
                    return [200, multiClassJurisdictions, {}];
                });

            var c = controller();
            http.flush();

            var result = c.allJurisdictionsMultiClass();

            expect(result).toBe(false);
        });
    });
});