describe('inprotech.configuration.general.validcombination', function() {
    'use strict';

    var controller, kendoGridBuilder, state, validCombConfig, validCombMaintenanceService, scope, selectedCaseTypeFactory, validCombService;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.components.grid', 'inprotech.mocks.configuration.validcombination']);
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);
            validCombMaintenanceService = $injector.get('ValidCombinationMaintenanceServiceMock');
            $provide.value('validCombinationMaintenanceService', validCombMaintenanceService);
            $provide.value('validCombinationService', $injector.get('ValidCombinationServiceMock'));
            $provide.value('appContext', {});
        });
    });

    beforeEach(inject(function($controller, $state, validCombinationConfig, $rootScope, selectedCaseType, validCombinationService) {
        scope = $rootScope.$new();
        validCombService = validCombinationService;

        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: scope,
                $state: state = $state,
                validCombinationConfig: validCombConfig = validCombinationConfig,
                selectedCaseType: selectedCaseTypeFactory = selectedCaseType,
                validCombinationService: validCombService,
                viewData: []
            }, dependencies);
            var c = $controller('ValidCombinationController', dependencies);
            c.$onInit();
            return c;
        };
    }));

    describe('initialisation', function() {
        it('should initialise controller', function() {
            var c = controller();

            expect(c.searchOptions).toBeDefined();
            expect(c.onSearchbyChanged).toBeDefined();
            expect(c.reset).toBeDefined();
            expect(c.refreshGrid).toBeDefined();
            expect(c.evalPicklistVisibility).toBeDefined();
            expect(c.isResetDisabled).toBeDefined();
            expect(c.isDefaultSelection).toBeDefined();
            expect(c.gridOptions).toBeDefined();
            expect(c.hasErrors).toBeDefined();
            expect(c.searchCriteria).toEqual({
                jurisdictions: [],
                propertyType: {},
                caseType: {},
                action: {},
                caseCategory: {},
                subType: {},
                basis: {},
                status: {},
                relationship: {},
                checklist: {},
                viewDefault: false
            });
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        });
    });

    describe('searching', function() {
        it('should retain search filters when search by option is changed', function() {
            var c = controller();
            c.searchCriteria = {
                jurisdictions: ['US', 'AU'],
                propertyType: {},
                caseType: {},
                action: {},
                subType: {},
                caseCategory: {},
                basis: {},
                status: {},
                relationship: {},
                checklist: {}
            };
            c.form = {};

            spyOn(c, 'refreshGrid');

            var keys = Object.keys(c.searchCriteria);
            _.each(keys, function(typeahead) {
                c.form[typeahead] = c.searchCriteria[typeahead];
            });

            c.reset();

            expect(c.searchCriteria.jurisdictions).toEqual(['US', 'AU']);
            expect(c.refreshGrid).toHaveBeenCalled();
        });
        it('should reset search filters when reset button is invoked', function() {
            var c = controller();
            c.searchCriteria = {
                jurisdictions: ['US', 'AU'],
                propertyType: {},
                caseType: {
                    'key': null,
                    'code': null,
                    'value': 'ettrr'
                },
                action: {},
                subType: {},
                caseCategory: {},
                basis: {},
                status: {},
                relationship: {},
                checklist: {}
            };

            c.form = {};

            spyOn(c, 'refreshGrid');

            var keys = Object.keys(c.searchCriteria);
            _.each(keys, function(typeahead) {
                c.form[typeahead] = c.searchCriteria[typeahead];
            });

            c.reset(true);

            expect(c.searchCriteria.jurisdictions).toEqual([]);
            expect(c.refreshGrid).toHaveBeenCalled();
            expect(validCombMaintenanceService.resetSearchCriteria).toHaveBeenCalledWith(c.searchCriteria);
        });
        it('should reset errors for invalid picklists and retain other search filters', function() {
            var c = controller();
            c.searchCriteria = {
                jurisdictions: ['US', 'AU'],
                propertyType: {},
                caseType: {
                    'key': null,
                    'code': null,
                    'value': 'ettrr'
                },
                action: {},
                subType: {},
                caseCategory: {},
                basis: {},
                status: {},
                relationship: {},
                checklist: {}
            };

            c.form = {};

            spyOn(c, 'refreshGrid');

            var keys = Object.keys(c.searchCriteria);
            _.each(keys, function(typeahead) {
                c.form[typeahead] = c.searchCriteria[typeahead];
            });

            c.form['caseType'].$reset = angular.noop;
            c.form['caseType'].$invalid = true;

            spyOn(c.form['caseType'], '$reset');

            c.reset();

            expect(c.searchCriteria.jurisdictions).toEqual(['US', 'AU']);
            expect(c.form['caseType'].$reset).toHaveBeenCalled();
            expect(c.refreshGrid).toHaveBeenCalled();
        });
        it('should set default selection', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.default
            };
            var isDefault = c.isDefaultSelection();
            expect(isDefault).toEqual(true);
        });
        it('should call maintenance service add function', function() {
            var c = controller();
            c.add();
            expect(validCombMaintenanceService.handleAddFromMainController).toHaveBeenCalled();
        });
        it('should go to default state when search by option is default', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.default
            };

            spyOn(c, 'reset');
            spyOn(state, 'go');

            c.onSearchbyChanged();
            expect(c.reset).toHaveBeenCalled();
            expect(state.go).toHaveBeenCalledWith(validCombConfig.baseStateName, {}, {
                reload: true
            });
        });
        it('should go to propertytype state when search by option is propertyType', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.propertyType
            };

            spyOn(c, 'reset');
            spyOn(state, 'go');

            c.onSearchbyChanged();
            expect(c.reset).toHaveBeenCalled();
            expect(state.go).toHaveBeenCalledWith(validCombConfig.baseStateName + '.' + c.selectedSearchOption.type);
        });
        it('should go to action state when search by option is action', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.action
            };

            spyOn(c, 'reset');
            spyOn(state, 'go');

            c.onSearchbyChanged();
            expect(c.reset).toHaveBeenCalled();
            expect(state.go).toHaveBeenCalledWith(validCombConfig.baseStateName + '.' + c.selectedSearchOption.type);
        });
        it('should go to subtype state when search by option is subType', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.subType
            };

            spyOn(c, 'reset');
            spyOn(state, 'go');

            c.onSearchbyChanged();
            expect(c.reset).toHaveBeenCalled();
            expect(state.go).toHaveBeenCalledWith(validCombConfig.baseStateName + '.' + c.selectedSearchOption.type);
        });
        it('should go to jurisdiction state when search by option is Jurisdiction', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.jurisdiction
            };

            spyOn(c, 'reset');
            spyOn(state, 'go');

            c.onSearchbyChanged();
            expect(c.reset).toHaveBeenCalled();
            expect(state.go).toHaveBeenCalledWith(validCombConfig.baseStateName + '.' + c.selectedSearchOption.type);
        });
        it('should go to basis state when search by option is basis', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.basis
            };

            spyOn(c, 'reset');
            spyOn(state, 'go');

            c.onSearchbyChanged();
            expect(c.reset).toHaveBeenCalled();
            expect(state.go).toHaveBeenCalledWith(validCombConfig.baseStateName + '.' + c.selectedSearchOption.type);
        });
        it('should go to date of law state when search by option is dateOfLaw', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.dateOfLaw
            };

            spyOn(c, 'reset');
            spyOn(state, 'go');

            c.onSearchbyChanged();
            expect(c.reset).toHaveBeenCalled();
            expect(state.go).toHaveBeenCalledWith(validCombConfig.baseStateName + '.' + c.selectedSearchOption.type);
        });
        it('should go to status state when search by option is status', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.status
            };

            spyOn(c, 'reset');
            spyOn(state, 'go');

            c.onSearchbyChanged();
            expect(c.reset).toHaveBeenCalled();
            expect(state.go).toHaveBeenCalledWith(validCombConfig.baseStateName + '.' + c.selectedSearchOption.type);
        });
        it('should go to relationship state when search by option is relationship', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.relationship
            };

            spyOn(c, 'reset');
            spyOn(state, 'go');

            c.onSearchbyChanged();
            expect(c.reset).toHaveBeenCalled();
            expect(state.go).toHaveBeenCalledWith(validCombConfig.baseStateName + '.' + c.selectedSearchOption.type);
        });
        it('should return false when search option is Default for evaluate picklist visibility', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.default
            };

            var isPicklistVisible = c.evalPicklistVisibility();
            expect(isPicklistVisible).toEqual(false);
        });
        it('should return true when search option is propertyType for jurisdiction picklist visibility', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.propertyType
            };

            var isPicklistVisible = c.evalPicklistVisibility('jurisdiction');
            expect(isPicklistVisible).toEqual(true);
        });
        it('should set the Case Type in selecteCaseType factory correctly', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.subType
            };
            c.searchCriteria.caseType = {
                'key': 'A',
                'code': 'A',
                'value': 'Property'
            };
            c.caseTypeChanged();
            expect(selectedCaseTypeFactory.get().key).toEqual('A');
            expect(selectedCaseTypeFactory.get().value).toEqual('Property');
        });
        it('should disable Case Category if Case Type is null', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.subType
            };
            expect(c.isCaseCategoryDisabled()).toEqual(true);
        });
        it('should disable Case Category if Case Type is not null', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.subType
            };
            c.searchCriteria.caseType = {
                'key': 'A',
                'code': 'A',
                'value': 'Property'
            };
            expect(c.isCaseCategoryDisabled()).toEqual(false);
        });
        // it('should go to chosen state when called directly from url', inject(function($httpBackend) {
        //     var c = controller();
        //     c.selectedSearchOption = {
        //         type: validCombConfig.searchType.propertyType
        //     };

        //     spyOn(c, 'reset');

        //     state.go(validCombConfig.baseStateName + '.' + validCombConfig.searchType.relationship);
        //     $httpBackend.when('GET', 'api/configuration/validcombination/viewData').respond(200);
        //     scope.$apply();
        //     $httpBackend.when('GET', 'condor/configuration/general/validcombination/validcombination.html').respond(200);
        //     scope.$apply();
        //     $httpBackend.when('GET', 'condor/configuration/general/validcombination/validcombination-resultset.html').respond(200);
        //     scope.$apply();
        //     $httpBackend.flush();

        //     expect(c.reset).toHaveBeenCalled();
        //     expect(state.current.symbol).toBe(validCombConfig.searchType.relationship);
        // }));
    });

    describe('picklist', function() {
        it('should return true when search option is propertyType for propertyType picklist visibility', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.propertyType
            };

            var isPicklistVisible = c.evalPicklistVisibility('propertytype');
            expect(isPicklistVisible).toEqual(true);

            c.selectedSearchOption = {
                type: validCombConfig.searchType.allCharacteristics
            };

            isPicklistVisible = c.evalPicklistVisibility('propertytype');
            expect(isPicklistVisible).toEqual(false);

            isPicklistVisible = c.evalPicklistVisibility('checklist');
            expect(isPicklistVisible).toEqual(false);
        });
        it('should return true when search option is action for casetype , jurisdiction, propertytype and action picklists', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.action
            };

            var isPicklistVisible = c.evalPicklistVisibility('casetype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('jurisdiction');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('propertytype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('action');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('checklist');
            expect(isPicklistVisible).toEqual(false);
        });
        it('should return true when search option is subType for caseType, jurisdiction, propertytype, category and subtype picklists', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.subType
            };

            var isPicklistVisible = c.evalPicklistVisibility('casetype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('jurisdiction');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('propertytype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('casecategory');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('subtype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('checklist');
            expect(isPicklistVisible).toEqual(false);
        });
        it('should return true when search option is Jurisdiction for jurisdiction picklist', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.subType
            };

            var isPicklistVisible = c.evalPicklistVisibility('jurisdiction');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('checklist');
            expect(isPicklistVisible).toEqual(false);
        });
        it('should return true when search option is basis for caseType, jurisdiction, propertytype, category and basis picklists', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.basis
            };

            var isPicklistVisible = c.evalPicklistVisibility('casetype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('jurisdiction');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('propertytype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('casecategory');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('basis');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('checklist');
            expect(isPicklistVisible).toEqual(false);
        });
        it('should return true when search option is Jurisdiction for jurisdiction picklist', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.subType
            };

            var isPicklistVisible = c.evalPicklistVisibility('jurisdiction');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('checklist');
            expect(isPicklistVisible).toEqual(false);
        });
        it('should return true when search option is DateOfLaw for dateoflaw picklist visibility', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.dateOfLaw
            };

            var isPicklistVisible = c.evalPicklistVisibility('propertytype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('jurisdiction');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('casecategory');
            expect(isPicklistVisible).toEqual(false);

            isPicklistVisible = c.evalPicklistVisibility('checklist');
            expect(isPicklistVisible).toEqual(false);
        });
        it('should return true when search option is category for category picklist visibility', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.category
            };

            var isPicklistVisible = c.evalPicklistVisibility('casetype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('propertytype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('jurisdiction');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('casecategory');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('checklist');
            expect(isPicklistVisible).toEqual(false);
        });
        it('should return true when search option is status for status picklist', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.status
            };

            var isPicklistVisible = c.evalPicklistVisibility('status');
            expect(isPicklistVisible).toEqual(true);
        });
        it('should return true when search option is relationship for relationship picklist visibility', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.relationship
            };

            var isPicklistVisible = c.evalPicklistVisibility('casetype');
            expect(isPicklistVisible).toEqual(false);

            isPicklistVisible = c.evalPicklistVisibility('propertytype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('jurisdiction');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('casecategory');
            expect(isPicklistVisible).toEqual(false);

            isPicklistVisible = c.evalPicklistVisibility('relationship');
            expect(isPicklistVisible).toEqual(true);
        });
        it('should return true when search option is checklist for checklist picklist visibility', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.checklist
            };

            var isPicklistVisible = c.evalPicklistVisibility('casetype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('propertytype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('jurisdiction');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('casecategory');
            expect(isPicklistVisible).toEqual(false);

            isPicklistVisible = c.evalPicklistVisibility('checklist');
            expect(isPicklistVisible).toEqual(true);
        });
        it('should disable search if any picklist is in invalid state', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.checklist
            };

            c.form = {
                $valid: false
            };

            expect(c.hasErrors()).toEqual(true);
        });
        it('should return true when search option is action for caseType and action picklists', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.action
            };

            var isPicklistVisible = c.evalPicklistVisibility('casetype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('jurisdiction');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('propertytype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('action');
            expect(isPicklistVisible).toEqual(true);
        });
        it('should return true when search option is subType for caseType, jurisdiction, propertytype, category and subtype picklists', function() {
            var c = controller();
            c.selectedSearchOption = {
                type: validCombConfig.searchType.subType
            };

            var isPicklistVisible = c.evalPicklistVisibility('casetype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('jurisdiction');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('propertytype');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('casecategory');
            expect(isPicklistVisible).toEqual(true);

            isPicklistVisible = c.evalPicklistVisibility('subtype');
            expect(isPicklistVisible).toEqual(true);
        });
    });
    describe('default jurisdiction feature', function() {
        it('flag true if jurisdiction picklist contains default jurisdiction', function() {
            var c = controller();
            c.searchCriteria.jurisdictions = [{
                key: 'ZZZ',
                code: 'ZZZ',
                value: 'DEFAULT FOREIGN COUNTRY'
            }, {
                key: 'AF',
                code: 'AF',
                value: 'AFGHANISTAN'
            }];

            expect(c.containsDefault()).toBe(true);
        });
        it('flag false if jurisdiction picklist does not contain default jurisdiction', function() {
            var c = controller();
            c.searchCriteria.jurisdictions = [{
                key: 'AF',
                code: 'AF',
                value: 'AFGHANISTAN'
            }];

            expect(c.containsDefault()).toBe(false);
        });
        it('default jurisdiction checkbox should be checked when user selects default jurisdiction from picklist', function() {
            var c = controller();
            c.searchCriteria.jurisdictions = [{
                key: 'AF',
                code: 'AF',
                value: 'AFGHANISTAN'
            }];

            c.searchCriteria.jurisdictions.push({
                key: 'ZZZ',
                code: 'ZZZ',
                value: 'DEFAULT FOREIGN COUNTRY'
            });

            c.onCountryChange();
            expect(c.searchCriteria.viewDefault).toBe(true);
        });
        it('default jurisdiction checkbox should be unchecked when user removes default jurisdiction from picklist', function() {
            var c = controller();
            c.searchCriteria.jurisdictions = [{
                key: 'AF',
                code: 'AF',
                value: 'AFGHANISTAN'
            }, {
                key: 'ZZZ',
                code: 'ZZZ',
                value: 'DEFAULT FOREIGN COUNTRY'
            }];

            c.searchCriteria.jurisdictions = _.without(c.searchCriteria.jurisdictions, _.findWhere(c.searchCriteria.jurisdictions, {
                key: 'ZZZ'
            }));

            c.onCountryChange();
            expect(c.searchCriteria.viewDefault).toBe(false);
        });
        it('default jurisdiction checkbox checked should add default jurisdiction in picklist', function() {
            var c = controller();
            c.searchCriteria.jurisdictions = [{
                key: 'AF',
                code: 'AF',
                value: 'AFGHANISTAN'
            }];
            c.searchCriteria.viewDefault = true;

            c.onViewDefaultChange();
            expect(c.searchCriteria.jurisdictions.length).toBe(2);
            expect(_.any(_.filter(c.searchCriteria.jurisdictions, function(jurisdiction) {
                return jurisdiction.key === 'ZZZ';
            }))).toBe(true);
        });
        it('default jurisdiction checkbox unchecked should remove default jurisdiction in picklist', function() {
            var c = controller();
            c.searchCriteria.jurisdictions = [{
                key: 'AF',
                code: 'AF',
                value: 'AFGHANISTAN'
            }, {
                key: 'ZZZ',
                code: 'ZZZ',
                value: 'DEFAULT FOREIGN COUNTRY'
            }];
            c.searchCriteria.viewDefault = false;

            c.onViewDefaultChange();
            expect(c.searchCriteria.jurisdictions.length).toBe(1);
            expect(_.any(_.filter(c.searchCriteria.jurisdictions, function(jurisdiction) {
                return jurisdiction.key === 'ZZZ';
            }))).toBe(false);
        });
    });
});
