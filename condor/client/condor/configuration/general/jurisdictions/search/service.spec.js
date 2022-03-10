describe('inprotech.configuration.general.jurisdictions.jurisdictionsService', function() {
    'use strict';

    var service, httpMock, store;

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);

            store = $injector.get('storeMock');
            $provide.value('store', store);
        });
    });

    beforeEach(inject(function(jurisdictionsService) {
        service = jurisdictionsService;
    }));

    describe('searching', function() {
        it('should pass correct parameters', function() {
            var criteria = {
                text: 'text'
            };
            var query = {
                text: 'text'
            };
            var queryParams = {
                sortBy: 'id',
                sortDir: 'asc',
                skip: 1,
                take: 2
            };
            service.search(criteria, queryParams);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/jurisdictions/search', {
                params: {
                    q: JSON.stringify(query),
                    params: JSON.stringify(queryParams)
                }
            });
            expect(store.local.set).toHaveBeenCalled();
        });

        it('should accept empty criteria', function() {
            var criteria = {};
            var query = {
                text: ''
            };
            service.search(criteria);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/jurisdictions/search', {
                params: {
                    q: JSON.stringify(query),
                    params: undefined
                }
            });
        });
    });
    describe('getColumnFilterData', function() {
        it('should get filter data', function() {
            var criteria = {
                text: 'text'
            };
            var query = {
                text: 'text'
            };
            service.search(criteria);

            httpMock.get.calls.reset();

            service.getColumnFilterData({
                field: 'field'
            });

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/jurisdictions/filterdata/field', {
                params: {
                    criteria: JSON.stringify(query)
                }
            });
        });
    });
});
