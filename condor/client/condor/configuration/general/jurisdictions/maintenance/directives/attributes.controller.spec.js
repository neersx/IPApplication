describe('inprotech.configuration.general.jurisdictions.AttributesController', function() {
    'use strict';

    var controller, kendoGridBuilder, service, parentId = 'AU';

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.jurisdictions', 'inprotech.mocks.components.grid']);

            service = $injector.get('JurisdictionAttributesServiceMock');
            $provide.value('jurisdictionAttributesService', service);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);
        });
    });

    beforeEach(inject(function($controller) {
        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: {
                    type: '0',
                    parentId: parentId,
                    vm: {
                        topic: { reportPriorArt: true }
                    }

                }
            }, dependencies);

            var c = $controller('AttributesController', dependencies, {
                topic: { canUpdate: true }
            });
            c.$onInit();
            return c;
        };
    }));

    it('initialize should initialise the grid', function() {
        var c = controller();
        expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        expect(c.gridOptions).toBeDefined();
        expect(service.getAttributeTypes).toHaveBeenCalled();
    });

    describe('grid', function() {
        it('should call correct Search Service', function() {
            var c = controller();
            var queryParams = {
                something: 'abc'
            };
            c.gridOptions.read(queryParams);
            expect(service.listAttributes).toHaveBeenCalledWith(queryParams, parentId);
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
            typeId: 1,
            valueId: 3,
            countryCode: 'AU'
        }]);
        c.formData.reportPriorArt = true;

        var r = c.topic.getFormData();

        expect(r).toEqual({
            attributesDelta: {
                added: [{
                    id: -1,
                    typeId: 1,
                    valueId: 3,
                    countryCode: 'AU'
                }],
                deleted: [],
                updated: []
            },
            attributes: c.gridOptions.dataSource.data(),
            reportPriorArt: c.formData.reportPriorArt
        });
    });

    it('attributesChange check duplicate row', function() {
        var c = controller();
        service.isDuplicated = _.constant(false);
        var obj = {
            error: jasmine.createSpy(),
            typeId: 1,
            valueId: 1
        };

        c.attributesChange(obj);

        expect(obj.error).toHaveBeenCalledWith('duplicate', false);
    });

    it('onAttributeTypesChanged with type null', function() {
        var c = controller();
        var obj = {
            error: _.noop,
            typeId: null
        };

        c.attributesTypeChange(obj);
        expect(obj.valueId).toBe(null);
    });

    it('onAttributeTypesChanged with type has some value', function() {
        var c = controller();
        var obj = {
            error: _.noop,
            typeId: 1
        };

        c.attributesTypeChange(obj);
        expect(service.getAttributes).toHaveBeenCalledWith(obj.typeId);
    });

    it('validate', function() {
        var c = controller();
        c.form = {
            $validate: _.constant(true)
        };

        expect(c.topic.validate()).toBe(true);
    });
});