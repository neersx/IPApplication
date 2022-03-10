describe('OverviewMaintenanceController', function() {
    'use strict';

    var controller, modalInstance, http;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() { 
            modalInstance = test.mock('$uibModalInstance', 'ModalInstanceMock');
            http = test.mock('$http', 'httpMock');
        });

        inject(function($controller) {
            controller = function(options) {
                var extOptions = {dataItem:{}};

                _.extend(extOptions, options);

                var returnController = $controller('OverviewMaintenanceController', {
                    $scope: {},
                    $uibModalInstance: modalInstance,
                    $http: http,
                    options: extOptions
                });

                return returnController;
            };
        });
    });

    describe('initialisation', function() {
        it('functions required by eventcontroller should be there', function() {

            var c = controller();

            expect(c.maintenanceState).toBe('updating');

            expect(c.apply).toBeDefined();
            expect(c.dismiss).toBeDefined();
            expect(c.saveWithoutValidate).toBeDefined();

            expect(c.isApplyEnabled).toBeDefined();
            expect(c.hasUnsavedChanges).toBeDefined();
        });
    });

    describe('eventscontroller integration', function(){
        it ('onBeforeSave is called when valid', function(){
            var c = controller();

            c.onBeforeSave = jasmine.createSpy();

            c.maintenance = {
                $validate: jasmine.createSpy().and.returnValue(true),
                $valid: true
            };

            c.apply();

            expect(c.maintenance.$validate).toHaveBeenCalled();
            expect(c.onBeforeSave).toHaveBeenCalled();
        });

        it ('onBeforeSave is NOT called when Invalid', function(){
            var c = controller();

            c.onBeforeSave = jasmine.createSpy();

            c.maintenance = {
                $validate: jasmine.createSpy().and.returnValue(false),
                $valid: false
            };

            c.apply();

            expect(c.maintenance.$validate).toHaveBeenCalled();
            expect(c.onBeforeSave).not.toHaveBeenCalled();
        });
    });

    describe('saving', function(){
        it('clicking save calls server and closes the window', function(){
            var c = controller();

            c.saveWithoutValidate();

            expect(http.put).toHaveBeenCalled();
            expect(modalInstance.close).toHaveBeenCalled();
        });
    });
});
