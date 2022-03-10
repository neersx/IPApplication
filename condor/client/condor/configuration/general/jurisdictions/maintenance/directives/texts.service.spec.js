describe('inprotech.configuration.general.jurisdictions.jurisdictionTextsService', function() {
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

    beforeEach(inject(function(jurisdictionTextsService) {
        service = jurisdictionTextsService;
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
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/jurisdictions/maintenance/texts/' + id, {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });
    });
});
