describe('inprotech.configuration.general.jurisdictions.jurisdictionGroupsService', function() {
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

    beforeEach(inject(function(jurisdictionGroupsService) {
        service = jurisdictionGroupsService;
    }));

    describe('searching', function() {
        it('should pass correct parameters', function() {
            var id = 'PCT';
            var type = 'members';
            var queryParams = {
                sortBy: 'id',
                sortDir: 'asc',
                skip: 1,
                take: 2
            };
            service.search(queryParams, id, type);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/jurisdictions/maintenance/' + type + '/' + id, {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });
    });
});
