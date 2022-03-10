describe('inprotech.processing.policing.ipQueueErrorviewController', function() {
    'use strict';

    var scope, controller, kendoGridBuilder, modalService, policingQueueService;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.processing.policing', 'inprotech.mocks.components.grid']);
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            policingQueueService = $injector.get('PolicingQueueServiceMock');
            $provide.value('policingQueueService', policingQueueService);

            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);
        });
    });

    beforeEach(inject(function($controller, $rootScope) {
        scope = $rootScope.$new();
        controller = function() {
            var c = $controller('ipQueueErrorviewController', { $scope: scope });
            c.$onInit();
            return c;
        };
    }));

    describe('initialize view model', function() {
        it('should initialize grid builder options', function() {
            controller();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        });
    });

    describe('click show all errors', function() {
        it('should call modalService', function() {
            var c = controller();
            c.viewErrors();
            expect(modalService.open).toHaveBeenCalledWith('PolicingQueueErrors', scope);
        });

        it('should run notification service when dialogue displays', function() {
            var c = controller();
            spyOn(scope, '$emit');
            c.viewErrors();
            expect(scope.$emit).toHaveBeenCalledWith('RefreshOnHold', true);
        });
    });
});
