describe('inprotech.processing.policing.PolicingRequestLogController', function() {
    'use strict';

    var scope, controller, kendoGridBuilder, requests, policingLogId, requestLogService, notificationService, promiseMock;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.processing.policing', 'inprotech.mocks.components.grid']);
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            requestLogService = $injector.get('PolicingRequestLogServiceMock');
            $provide.value('policingRequestLogServiceMock', requestLogService);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            test.mock('dateService');
            promiseMock = $injector.get('promiseMock');

            requests = {};
            policingLogId = 1;
        });
    });

    beforeEach(inject(function($controller, $rootScope) {
        scope = $rootScope.$new();
        scope.data = requests;
        requestLogService.delete = promiseMock.createSpy({
            result: {
                status: 'success'
            }
        });
        controller = function() {
            return $controller('PolicingRequestLogController', {
                $scope: scope,
                viewData: {
                    canViewOrMaintainRequests: true
                },
                policingLogId: policingLogId,
                policingRequestLogService: requestLogService
            });
        };        
    }));

    describe('initialize view model', function() {
        it('should initialize', function() {
            var c = controller();
            c.$onInit();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.policingLogId).toEqual(policingLogId);
        });
    });

    describe('when delete button clicked', function() {
        it('asks to confirm delete policing log', function() {
            var c = controller();
            c.$onInit();
            c.deleteRow(c.policingLogId);

            expect(notificationService.confirmDelete).toHaveBeenCalledWith({
                message: 'policing.request.log.deleteConfirmMessage'
            });
        });
        it('correct api call is made', function() {
            notificationService.confirmDelete = promiseMock.createSpy();
            notificationService.success = promiseMock.createSpy();
            var c = controller();
            c.$onInit();
            c.deleteRow(c.policingLogId);

            expect(requestLogService.delete).toHaveBeenCalledWith(c.policingLogId);
        });
    });
});
