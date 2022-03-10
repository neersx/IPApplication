angular.module('inprotech.processing.policing')
    .service('policingRequestLogService', function($http, $translate) {
        'use strict';

        return {
            get: function(queryParams) {
                return $http.get('api/policing/requestlog/', {
                        params: {
                            params: JSON.stringify(queryParams)
                        }
                    })
                    .then(function(response) {
                        return response.data;
                    });
            },
            getColumnFilterData: function(column, columnFilters) {
                return $http.get('api/policing/requestlog/filterData/' + column.field, {
                    params: {
                        columnFilters: JSON.stringify(columnFilters)
                    }
                }).then(function(response) {
                    if (column.field === 'status') {
                        return _.each(response.data, function(filter) {
                            filter.description = $translate.instant('policing.request.log.' + filter.code)
                        });
                    }
                    return response.data;
                });
            },
            getErrors: function(policingLogId, queryParams) {
                return $http.get('api/policing/requestlog/errors/' + policingLogId, {
                        params: {
                            params: JSON.stringify(queryParams)
                        }
                    })
                    .then(function(response) {
                        return response.data;
                    });
            },
            recent: function() {
                return $http.get('api/policing/requestlog/recent')
                    .then(function(response) {
                        return response.data;
                    });
            },
            delete: function(policingLogId) {
                return $http.get('api/policing/requestlog/delete/' + policingLogId)
                    .then(function(response) {
                        return response.data;
                    });
            }
        };
    });
