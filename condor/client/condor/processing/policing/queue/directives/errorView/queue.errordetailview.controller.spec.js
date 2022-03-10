describe('inprotech.processing.policing.ipQueueErrordetailviewController', function() {
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
            return $controller('ipQueueErrordetailviewController', { $scope: scope });
        };
    }));

    describe('initialize view model', function() {
        it('should initialize grid builder options', function() {
            controller();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        });
    });

    describe('click dismiss modal', function() {
        it('should dismiss modal', function() {
            controller();
            modalService.close = jasmine.createSpy('modal close spy');
            scope.dismissAll();
            expect(modalService.close).toHaveBeenCalledWith('PolicingQueueErrors');
        });

        it('should run notification service when dialogue displays', function() {
            controller();
            modalService.close = jasmine.createSpy('modal close spy');

            spyOn(scope, '$emit');
            scope.dismissAll();
            expect(scope.$emit).toHaveBeenCalledWith('RefreshOnHold', false);
        });
    });
});
