describe('inprotech.configuration.general.validcombination.action', function() {
    'use strict';

    var controller, kendoGridBuilder, scope, parentController;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.components.grid']);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);
        });
    });

    beforeEach(inject(function($rootScope, $controller) {
        var parentScope = $rootScope.$new();
        parentController = function(dependencies) {
            dependencies = angular.extend({
                $scope: parentScope,
                viewData: []
            }, dependencies);
            var pc = $controller('ValidCombinationController', dependencies);
            pc.$onInit();
            return pc;
        };
        controller = function(dependencies) {
            scope = $rootScope.$new();
            scope.vm = parentController();
            dependencies = angular.extend({
                $scope: scope
            }, dependencies);
            return $controller('ValidJurisdictionController', dependencies);
        };
    }));

    describe('initialisation', function() {
        it('should initialise controller', function() {
            var c = controller();

            expect(c.search).toBeDefined();
            expect(c.context).toEqual('jurisdiction');
            expect(c.gridOptions).toBeDefined();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        });
        it('should set default search criteria where specified', function() {
            var c = controller({
                $stateParams: {
                    searchKey: 'AU',
                    searchName: 'Australia'
                }
            });

            expect(c.search).toBeDefined();
            expect(c.context).toEqual('jurisdiction');
            expect(c.gridOptions).toBeDefined();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(_.pluck(scope.vm.searchCriteria.jurisdictions, 'key')).toEqual(['AU']);
            expect(_.pluck(scope.vm.searchCriteria.jurisdictions, 'code')).toEqual(['AU']);
            expect(_.pluck(scope.vm.searchCriteria.jurisdictions, 'value')).toEqual(['Australia']);
        });
    });

    describe('searching', function() {
        it('should set reset button as disabled when no filter is added', function() {
            scope.vm.searchCriteria = {
                jurisdictions: [],
                propertyType: {},
                caseType: {},
                caseCategory: {},
                subType: {}
            };
            scope.vm.form = {
                $valid: true
            };
            scope.vm.selectedSearchOption = {
                type : 'default'
            };
            var result = scope.vm.isResetDisabled();
            expect(result).toEqual(true);
        });
        it('should call search when search button is clicked', function() {
            var c = controller();

            c.search();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });
        it('should refresh grid when reset button is clicked', function() {
            var c = controller();

            c.gridOptions.data = function() {
                return [1, 2];
            };

            scope.vm.refreshGrid();
            expect(c.gridOptions.clear).toHaveBeenCalled();
        });
    });

});
