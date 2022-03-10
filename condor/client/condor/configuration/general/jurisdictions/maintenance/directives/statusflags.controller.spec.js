describe('inprotech.configuration.general.jurisdictions.StatusFlagsController', function() {
    'use strict';

    var controller, kendoGridBuilder, service;
    var parentId = 'EP';

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.jurisdictions', 'inprotech.mocks.components.grid']);

            service = $injector.get('JurisdictionStatusFlagsServiceMock');
            $provide.value('jurisdictionStatusFlagsService', service);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);
        });
    });

    beforeEach(inject(function($controller) {
        controller = function() {
            var c = $controller('StatusFlagsController', {
                $scope: {
                    parentId: parentId
                }
            }, {
                topic: { canUpdate: true }
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
            expect(service.copyProfiles).toHaveBeenCalled();
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
            name: 'Pay Renewal Fee',
            restrictRemoval: false,
            allowNationalPhase: true,
            profileName: 'Basic Details',
            status: 'Pending'
        }]);

        var r = c.topic.getFormData();

        expect(r).toEqual({
            statusFlagsDelta: {
                added: [{
                    id: -1,
                    countryId: parentId,
                    name: 'Pay Renewal Fee',
                    restrictRemoval: false,
                    allowNationalPhase: true,
                    profileName: 'Basic Details',
                    status: 'Pending'
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
});