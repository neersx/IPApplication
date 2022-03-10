describe('inprotech.processing.policing.PolicingRequestLogService', function() {
    'use strict';

    var service, httpMock, queryParams, otherFilters;

    beforeEach(function() {
        module('inprotech.processing.policing');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.processing.policing']);

            httpMock = $injector.get('httpMock');
            httpMock.get.returnValue = {};

            $provide.value('$http', httpMock);
        });

        queryParams = {
            sortBy: 'any',
            sortDir: 'asc',
            skip: 1,
            take: 2
        };

        otherFilters = [{
            field: 'status',
            operator: 'in',
            value: 'test'
        }];
    });

    beforeEach(inject(function(policingRequestLogService) {
        service = policingRequestLogService;
    }));

    describe('policing request log', function() {
        it('should return all queue items', function() {
            service.get(queryParams);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/requestlog/', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });
    });

    describe('policing queue filter', function() {
        it('should return available filters for policing name', function() {

            var userColumnDef = {
                field: 'policingName'
            };
            service.getColumnFilterData(userColumnDef, otherFilters);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/requestlog/filterData/policingName', {
                params: {
                    columnFilters: JSON.stringify(otherFilters)
                }
            });
        });

        it('should return available filters for status', function() {

            var statusColumnDef = {
                field: 'status'
            };
            service.getColumnFilterData(statusColumnDef, otherFilters);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/requestlog/filterData/status', {
                params: {
                    columnFilters: JSON.stringify(otherFilters)
                }
            });
        });
    });

    describe('policing request log error', function() {
        it('should return all errors', function() {
            var id = 1;
            service.getErrors(id, queryParams);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/requestlog/errors/' + id, {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });
    });

    describe('delete policing request log', function() {
        it('should call the delete api correctly', function() {
            var id = 1;
            service.delete(id);
            expect(httpMock.get).toHaveBeenCalledWith('api/policing/requestlog/delete/' + id);
        });
    });
});
