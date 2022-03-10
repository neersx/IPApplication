describe('inprotech.processing.policing.ipPolicingRequestLogsummaryController', function() {
    'use strict';

    var scope, controller, kendoGridBuilder, requestLogService;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.processing.policing', 'inprotech.mocks.components.grid']);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            requestLogService = $injector.get('PolicingRequestLogServiceMock');
            $provide.value('policingRequestLogService', requestLogService);
        });
    });

    beforeEach(inject(function($controller, $rootScope) {
        scope = $rootScope.$new();
        
        controller = function() {
            var c = $controller('ipPolicingRequestLogsummaryController', {
                $scope: scope
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialize view model', function() {
        beforeEach(function() {

            requestLogService.recent.returnValue = {
                canViewOrMaintainRequests: true,
                requests: []
            };
        })

        it('should initialize grid builder options', function() {
            controller();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        });
    });
    describe('policing request', function() {
        it('should call openMaintenanceDialog if requestId is valid', function() {
            var c = controller();
            var spy = spyOn(c, 'openMaintenanceDialog');
            c.goToPolicingRequest(1);
            expect(spy).toHaveBeenCalled();
        });
        it('should not call openMaintenanceDialog if requestId is null', function() {
            var c = controller();
            var spy = spyOn(c, 'openMaintenanceDialog');
            c.goToPolicingRequest(null);
            expect(spy).not.toHaveBeenCalled();
        });
    });
});
