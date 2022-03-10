describe('inprotech.configuration.general.jurisdictions.TextsController', function() {
    'use strict';

    var controller, kendoGridBuilder, service, attributesService;
    var parentId = 'ZZ';

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.jurisdictions', 'inprotech.mocks.components.grid']);

            service = $injector.get('JurisdictionMaintenanceServiceMock');
            $provide.value('jurisdictionTextsService', service);

            attributesService = $injector.get('JurisdictionAttributesServiceMock');
            $provide.value('jurisdictionAttributesService', attributesService);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);
        });
    });

    beforeEach(inject(function($controller) {
        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: {
                    type: '0',
                    parentId: parentId
                }
            }, dependencies);

            var c = $controller('TextsController', dependencies, {
                topic: {
                    canUpdate: true
                }
            });
            c.$onInit();
            return c;
        };
    }));

    it('initialize should initialise the grid', function() {
        var c = controller();
        expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        expect(c.gridOptions).toBeDefined();
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
                countryCode: 'ZZ',
                sequenceId: -1,
                propertyType: {
                    key: 1,
                    code: 'a',
                    value: 'abc'
                },
                textType: {
                    key: 1,
                    code: 'x',
                    value: 'xyz'
                },
                text: 'test'
            }]);

            var r = c.topic.getFormData();

            expect(r).toEqual({
                textsDelta: {
                    added: [{
                        countryCode: 'ZZ',
                        propertyType: {
                            key: 1,
                            code: 'a',
                            value: 'abc'
                        },
                        textType: {
                            key: 1,
                            code: 'x',
                            value: 'xyz'
                        },
                        text: 'test',
                        sequenceId: -1
                    }],
                    deleted: [],
                    updated: []
                }
            });
        });

        it('onPicklistValueChange check duplicate row for false', function() {
            var c = controller();
            attributesService.isDuplicated = _.constant(false);
            var obj = {
                error: jasmine.createSpy(),
                propertyType: {
                    key: 1,
                    code: 'a',
                    value: 'abc'
                },
                textType: {
                    key: 1,
                    code: 'x',
                    value: 'xyz'
                }
            };

            c.onPicklistValueChange(obj);

            expect(obj.error).toHaveBeenCalledWith('duplicate', false);
        });

        it('onPicklistValueChange check duplicate row for true', function() {
            var c = controller();
            attributesService.isDuplicated = _.constant(true);
            var obj = {
                error: jasmine.createSpy(),
                propertyType: {
                    key: 1,
                    code: 'a',
                    value: 'abc'
                },
                textType: {
                    key: 1,
                    code: 'x',
                    value: 'xyz'
                }
            };

            c.gridOptions.dataSource.data = _.constant([{
                hasError: jasmine.createSpy(),
                added: true,
                countryCode: 'ZZ',
                sequenceId: -1,
                propertyType: {
                    key: 1,
                    code: 'a',
                    value: 'abc'
                },
                textType: {
                    key: 1,
                    code: 'x',
                    value: 'xyz'
                },
                text: 'test'
            }]);

            c.onPicklistValueChange(obj);

            expect(obj.error).toHaveBeenCalledWith('duplicate', true);
        });

        it('validate for true', function() {
            var c = controller();
            c.form = {
                $validate: _.constant(true)
            };

            expect(c.topic.validate()).toBe(true);
        });

        it('validate for false', function() {
            var c = controller();
            c.form = {
                $validate: _.constant(false)
            };

            expect(c.topic.validate()).toBe(false);
        });
    });
});