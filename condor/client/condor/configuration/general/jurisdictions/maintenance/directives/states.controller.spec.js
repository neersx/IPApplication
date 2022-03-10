describe('inprotech.configuration.general.jurisdictions.StatesController', function() {
    'use strict';

    var controller, kendoGridBuilder, service;
    var parentId = 'ABC';

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.jurisdictions', 'inprotech.mocks.components.grid']);

            service = $injector.get('JurisdictionMaintenanceServiceMock');
            $provide.value('jurisdictionStatesService', service);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);
        });
    });

    beforeEach(inject(function($controller) {
        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: {
                    parentId: parentId
                }
            }, dependencies);
            var c = $controller('StatesController', dependencies, {
                topic: {
                    canUpdate: true
                }
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialise', function() {
        it('should initialise the page, and have the correct grid columns', function() {
            var c = controller();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
        });
        it('should use specified State literal where available', function() {
            var c = controller({
                $scope: {
                    parentId: parentId,
                    stateLabel: 'Province'
                }
            });
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
            expect(_.pluck(c.gridOptions.columns, 'title')).toEqual(['Province', 'Province Name']);
        });
        it('should use default State literal if none specified', function() {
            var c = controller({
                $scope: {
                    parentId: parentId
                }
            });
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
            expect(_.pluck(c.gridOptions.columns, 'title')).toEqual(['jurisdictions.maintenance.states.state', 'jurisdictions.maintenance.states.state Name']);
        });
    });

    describe('grid', function() {
        it('should call correct Search Service', function() {
            var c = controller();
            var queryParams = {
                something: 'abc'
            };
            c.gridOptions.read(queryParams);
            expect(service.search).toHaveBeenCalledWith(queryParams, parentId);
        });
    });
    it('onAddClick should insert row at end', function() {
        var c = controller();

        c.gridOptions.dataSource.total = _.constant(10);
        c.onAddClick();

        expect(c.gridOptions.insertRow).toHaveBeenCalledWith(10, jasmine.any(Object));
    });
    it('hasError', function() {
        var c = controller();

        c.form = {
            $invalid: true
        };

        expect(c.topic.hasError()).toBe(true);

        c.form = {
            $invalid: false
        };

        c.gridOptions.dataSource.data = _.constant([]);

        expect(c.topic.hasError()).toBe(false);
    });

    it('isDirty', function() {
        var c = controller();
        c.gridOptions.dataSource.data = _.constant([{
            added: true
        }]);
        expect(c.topic.isDirty()).toBe(true);
    });
    it('getFormData', function() {
        var c = controller();
        c.gridOptions.dataSource.data = _.constant([{
            added: true,
            id: -1,
            countryCode: parentId,
            code: '01',
            name: 'State 01'
        }]);

        var r = c.topic.getFormData();

        expect(r).toEqual({
            stateDelta: {
                added: [{
                    id: -1,
                    countryId: parentId,
                    code: '01',
                    name: 'State 01'
                }],
                deleted: [],
                updated: []
            }
        });
    });
    it('validate', function() {
        var c = controller();
        c.form = {
            $validate: _.constant(true)
        };

        expect(c.topic.validate()).toBe(true);
    });

    describe('set in use error', function() {
        it('should call the applyInUseError when inUseItems is not null', function() {
            var c = controller();
            var inUseItems = [{
                id: 1,
                code: 'Test'
            }];

            c.applyInUseError = jasmine.createSpy();
            c.topic.setInUseError(inUseItems);

            expect(c.applyInUseError).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 1,
                    code: 'Test'
                })));
        });
        it('should not call the applyInUseError when inUseItems is null', function() {
            var c = controller();
            var inUseItems = null;

            c.applyInUseError = jasmine.createSpy();
            c.topic.setInUseError(inUseItems);

            expect(c.applyInUseError).not.toHaveBeenCalled();
        });
    });
});