describe('inprotech.configuration.general.validcombination.ActionOrderController', function() {
    'use strict';

    var controller, scope, service, options, kendoGridBuilder, modalService;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.validcombination', 'inprotech.mocks', 'inprotech.mocks.components.grid']);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);
            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);
            $provide.value('validCombinationService', $injector.get('ValidCombinationServiceMock'));
        });
    });

    beforeEach(inject(function($rootScope, $controller, validCombinationService) {
        scope = $rootScope.$new();
        service = validCombinationService;
        var allItems = [{
            jurisdiction: {
                key: 'AU',
                code: 'AU',
                value: 'Australia'
            },
            propertyType: {
                key: 'P',
                code: 'P',
                value: 'Patents'
            },
            caseType: {
                key: 'P',
                code: 'P',
                value: 'Properties'
            },
            action: {}
        }, {
            jurisdiction: {
                key: '',
                code: '',
                value: ''
            },
            propertyType: {
                key: '',
                code: '',
                value: ''
            },
            caseType: {
                key: '',
                code: '',
                value: ''
            },
            action: {}
        }];

        options = {
            allItems: allItems,
            dataItem: _.first(allItems)
        };

        controller = function(dependencies) {
            if (!dependencies) {
                dependencies = {
                    validCombinationService: service,
                    options: _.extend({}, options),
                    kendoGridBuilder: kendoGridBuilder,
                    modalService: modalService
                };
            }
            dependencies.$scope = scope;
            return $controller('ActionOrderController', dependencies);
        };
    }));

    describe('initialisation', function() {
        it('should initialise controller', function() {
            var c = controller();

            expect(c.displayNoItems).toEqual(false);
            expect(c.hint).toEqual('validcombinations.actionSearchHint');
            expect(c.dismiss).toBeDefined();
            expect(c.save).toBeDefined();
            expect(c.onFilterCriteriaChanged).toBeDefined();
            expect(c.filterCriteria).toBeDefined();
            expect(c.picklistErrors).toBeDefined();
            expect(c.gridOptions).toBeDefined();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        });
    });
    describe('do search', function() {
        it('should hide hint and hide No Items to display section when filter criteria are valid and service returns no data', function() {
            var c = controller();

            c.filterCriteria.jurisdiction = {
                key: 'AU',
                code: 'AU',
                value: 'Australia'
            };
            c.filterCriteria.propertyType = {
                key: 'D',
                code: 'D',
                value: 'Designs'
            };
            c.filterCriteria.caseType = {
                key: 'A',
                code: 'A',
                value: 'Properties'
            };

            c.gridOptions.dataSource = {
                data: function(d) {
                    return d;
                }
            };

            c.gridOptions.data = function() {
                return [];
            };

            service.validActions = function() {
                return {
                    then: function(cb) {
                        var response = {
                            data: []
                        };
                        return cb(response);
                    }
                };
            };

            c.onFilterCriteriaChanged();

            expect(c.hint).toEqual('');
            expect(c.displayNoItems).toBe(true);
        });
        it('should set hint and displayNoItems when filter criteria are valid and service returns no data', function() {
            var c = controller();

            c.filterCriteria.jurisdiction = {
                key: 'AU',
                code: 'AU',
                value: 'Australia'
            };
            c.filterCriteria.propertyType = {
                key: 'D',
                code: 'D',
                value: 'Designs'
            };
            c.filterCriteria.caseType = {
                key: 'A',
                code: 'A',
                value: 'Properties'
            };

            var data = [{
                id: 1
            }, {
                id: 2
            }];

            c.gridOptions.dataSource = {
                data: function(d) {
                    return d;
                }
            };

            c.gridOptions.data = function() {
                return data;
            };

            service.validActions = function() {
                return {
                    then: function(cb) {
                        var response = {
                            data: data
                        };
                        return cb(response);
                    }
                };
            };

            c.onFilterCriteriaChanged();

            expect(c.hint).toEqual('validcombinations.actionOrderHint');
        });
        it('should set hint and displayNoItems when filter criteria are invalid', function() {
            var c = controller();

            c.filterCriteria.jurisdiction = {
                key: '',
                code: 'AU',
                value: 'Australia'
            };
            c.filterCriteria.propertyType = {};
            c.filterCriteria.caseType = {
                key: 'A',
                code: 'A',
                value: 'Properties'
            };

            c.onFilterCriteriaChanged();

            expect(c.hint).toEqual('validcombinations.actionSearchHint');
            expect(c.displayNoItems).toBe(false);
        });
    });
    describe('modal operations', function() {
        it('should close modal when dismiss is called', function() {
            var c = controller();
            c.hasChanges = false;

            c.dismiss();

            expect(modalService.close).toHaveBeenCalledWith('ActionOrder');
        });
    });
});
