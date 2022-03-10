angular.module('Inprotech.BulkCaseImport').factory('bulkCaseImportService', function($http) {
    'use strict';

    var service = {
        getImportStatus: function(query) {
            return $http.get('api/bulkCaseImport/importStatus', {
                params: {
                    params: JSON.stringify(query)
                }
            }).then(function(data) {
                return data.data;
            });
        },
        getImportStatusColumnFilterData: function(column) {
            return $http.get('api/bulkCaseImport/importStatus/filterData/' + column).then(function(data) {
                return data.data;
            });
        },

        getBatchSummary: function(batchId, transReturnCode, queryParams) {
            return $http.get('api/bulkCaseImport/batchSummary?batchId=' + batchId + ((transReturnCode) ? '&transReturnCode=' + transReturnCode : ''), {
                params: {
                    params: JSON.stringify(queryParams)
                }
            }).then(function(data) {
                return data.data;
            });
        },

        getBatchSummaryColumnFilterData: function(batchId, transReturnCode, column) {
            return $http.get('api/bulkCaseImport/batchSummary/filterData/' + column +
                '?batchId=' + batchId + ((transReturnCode) ? '&transReturnCode=' + transReturnCode : '')).then(function(data) {
                return data.data;
            });
        }
    }
    return service;
});