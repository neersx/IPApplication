describe('inprotech.processing.policing.policingServerService', function() {
    'use strict';
    var service, httpMock;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');

            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function(policingServerService) {
        service = policingServerService;
    }));

    describe('policing server administration functions', function() {
        it('check access permissions', function() {
            service.canAdminister();
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/dashboard/permissions');
        });

        it('turns off policing continous server', function() {
            service.turnOff();
            expect(httpMock.post).toHaveBeenCalledWith('api/policing/dashboard/admin/turnOff');
        });

        it('turns on policing continous server', function() {
            service.turnOn();
            expect(httpMock.post).toHaveBeenCalledWith('api/policing/dashboard/admin/turnOn');
        });

    });
});
