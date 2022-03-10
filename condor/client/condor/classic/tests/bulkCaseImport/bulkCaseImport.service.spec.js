describe('Inprotech.BulkCaseImport.importStatusController', function() {
    'use strict';

    var service, httpMock;

    beforeEach(function() {
        module('Inprotech.BulkCaseImport');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function(bulkCaseImportService) {
        service = bulkCaseImportService;
    }));

    describe('searching', function() {
        it('should pass correct parameters', function() {
            var queryParams = {
                skip: 1,
                take: 2
            };
            service.getImportStatus(queryParams);
            expect(httpMock.get).toHaveBeenCalledWith('api/bulkCaseImport/importStatus', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });
    });

    describe('get import status filters', function() {
        it('should pass correct parameters', function() {
            var column = 'displayStatusType';
            service.getImportStatusColumnFilterData(column);
            expect(httpMock.get).toHaveBeenCalledWith('api/bulkCaseImport/importStatus/filterData/displayStatusType');
        });
    });

    describe('searching batch summary', function() {
        it('should pass correct parameters', function() {
            var batchId = '100';
            var transReturnCode = '38484';
            var queryParams = {
                skip: 1,
                take: 2
            };
            service.getBatchSummary(batchId, transReturnCode, queryParams);
            expect(httpMock.get).toHaveBeenCalledWith('api/bulkCaseImport/batchSummary?batchId=100&transReturnCode=38484', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            });
        });
    });

    describe('get batch summary filters', function() {
        it('should pass correct parameters', function() {
            var batchId = '100';
            var transReturnCode = '38484';
            var column = 'displayStatusType';
            service.getBatchSummaryColumnFilterData(batchId, transReturnCode, column);
            expect(httpMock.get).toHaveBeenCalledWith('api/bulkCaseImport/batchSummary/filterData/displayStatusType?batchId=100&transReturnCode=38484');
        });
    });

});