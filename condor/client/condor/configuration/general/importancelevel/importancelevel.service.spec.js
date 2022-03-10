describe('inprotech.configuration.general.importancelevel.service', function() {
    'use strict';

    var service, httpMock;

    beforeEach(function() {
        module('inprotech.configuration.general.importancelevel');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function(importanceLevelService) {
        service = importanceLevelService;
    }));

    describe('searching', function() {
        it('should pass correct parameters', function() {
            service.search();

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/importancelevel/search');
        });
    });
    describe('save', function() {
        it('should post importance grid delta', function() {
            var formDelta = {
                added: [],
                updated: [],
                deleted: []
            };

            service.save(formDelta);

            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/importancelevel/', formDelta);
        });
    });
});