describe('inprotech.configuration.general.jurisdictions.jurisdictionStatusFlagsService', function() {
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

    beforeEach(inject(function(jurisdictionStatusFlagsService) {
        service = jurisdictionStatusFlagsService;
    }));

    describe('listing', function() {
        it('should call the correct endpoint and pass the correct parameters', function() {
            var id = 'ZZZ';
            var queryParams = {
                sortBy: 'id',
                sortDir: 'asc',
                skip: 1,
                take: 2
            };
            service.search(queryParams, id);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/jurisdictions/maintenance/statusflags/' + id, {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });
    });
});

