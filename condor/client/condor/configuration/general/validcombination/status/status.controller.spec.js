describe('inprotech.configuration.general.validcombination.status', function() {
    'use strict';

    var stateParam, controller, kendoGridBuilder, scope, parentController, validCombMaintenanceService;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.components.grid', 'inprotech.mocks.configuration.validcombination']);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            validCombMaintenanceService = $injector.get('ValidCombinationMaintenanceServiceMock');
            $provide.value('validCombinationMaintenanceService', validCombMaintenanceService);
        });
    });

    beforeEach(inject(function($rootScope, $controller, $stateParams) {
        stateParam = $stateParams;
        parentController = function(dependencies) {
            var parentScope = $rootScope.$new();
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
            dependencies.$stateParams = stateParam;
            return $controller('ValidStatusController', dependencies);
        };
    }));

    describe('initialisation', function() {
        it('should initialise controller', function() {
            var c = controller();

            expect(c.search).toBeDefined();
            expect(c.context).toEqual('status');
            expect(c.gridOptions).toBeDefined();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        });
    });

    describe('searching', function() {
        it('should set reset button as disabled when no filter is added', function() {
            scope.vm.searchCriteria = {
                jurisdictions: [],
                propertyType: {},
                caseType: {},
                caseCategory: {},
                subType: {},
                status: {}
            };
            scope.vm.selectedSearchOption = {
                type : 'default'
            };

            scope.vm.form = {
                $valid: true
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
            c.gridOptions = {
                data: function() {
                    return [{
                        id: 1
                    }];
                }
            };
            c.gridOptions.clear = jasmine.createSpy();

            scope.vm.refreshGrid();
            expect(c.gridOptions.clear).toHaveBeenCalled();
            expect(validCombMaintenanceService.resetBulkMenu).toHaveBeenCalled();
        });
        it('should call clear saved rows method of service when search button is clicked', function() {
            var c = controller();

            c.search(true);
            expect(c.gridOptions.search).toHaveBeenCalled();
            expect(validCombMaintenanceService.clearSavedRows).toHaveBeenCalled();
        });
    });

    describe('stateparam', function() {
        it('should set searchCriteria.status search when stateparam.status is passed', function() {
            stateParam.status = {
                'id': '1',
                'name': 'abc'
            };
            
            controller();
            expect(scope.vm.searchCriteria.status.key).toEqual(stateParam.status.id);
            expect(scope.vm.searchCriteria.status.value).toEqual(stateParam.status.name);            
        });

        it('searchCriteria.status.key and searchCriteria.status.value should be null when stateparam.status is not passed', function() {
                       
            controller();
            expect(scope.vm.searchCriteria.status.key).toEqual(undefined);
            expect(scope.vm.searchCriteria.status.value).toEqual(undefined);            
        });

    });



});
