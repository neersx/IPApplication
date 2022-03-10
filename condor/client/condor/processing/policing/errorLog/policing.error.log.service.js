angular.module('inprotech.processing.policing')
    .service('policingErrorLogService', function($http) {
        'use strict';

        return {
            get: function(queryParams) {
                return $http.get('api/policing/errorlog/', {
                        params: {
                            params: JSON.stringify(queryParams)
                        }
                    })
                    .then(function(response) {
                        return response.data;
                    });
            },
            getColumnFilterData: function(column, columnFilters) {
                return $http.get('api/policing/errorlog/filterData/' + column.field, {
                        params: {
                            columnFilters: JSON.stringify(columnFilters)
                        }
                    })
                    .then(function(response) {
                        return response.data;
                    });
            },
            delete: function(ids) {
                return $http.post('api/policing/errorlog/delete', ids);
            },
            InprogressEnum: {
                none: 'none',
                queue: 'queue',
                request: 'request'
            }
        };
    });
