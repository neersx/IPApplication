describe('inprotech.configuration.general.jurisdictions.jurisdictionCombinationsService', function() {
    'use strict';

    var service, httpMock;

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');

            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function(jurisdictionCombinationsService) {
        service = jurisdictionCombinationsService;
    }));

    describe('searching', function() {
        it('should pass correct parameters', function() {
            var id = 'PCT';
            service.hasCombinations(id);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/jurisdictions/maintenance/combinations/' + id);
        });
    });
});
