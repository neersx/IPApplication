angular.module('inprotech.processing.policing')
    .service('policingQueueService', function($http, $translate, policingQueueFilterService) {
        'use strict';

        var knownTypes = ['all', 'on-hold', 'progressing', 'requires-attention'];

        var defaultConfig = {
            permissions: {
                canAdminister: false,
                canMaintainWorkflow: false
            }
        };

        var ensureValid = function(type) {
            if (!type || !_.any(knownTypes, function(t) {
                    return t === type;
                })) {
                return 'all';
            }
            return type;
        };

        var getRecordIds = function(records) {
            return _.pluck(records, 'requestId');
        };

        var summaryCache = {};

        return {
            get: function(type, queryParams) {
                return $http.get('api/policing/queue/' + ensureValid(type), {
                        params: {
                            params: JSON.stringify(queryParams)
                        }
                    })
                    .then(function(response) {
                        summaryCache = response.data.summary;
                        return response.data.items;
                    });
            },
            getCachedSummary: function() {
                return summaryCache;
            },
            getColumnFilterData: function(column, queueType, filtersForColumn, otherFilters) {
                return $http.get('api/policing/queue/filterData/' + column.field + '/' + queueType, {
                    params: {
                        columnFilters: JSON.stringify(otherFilters)
                    }
                }).then(function(response) {
                    if (column.field === 'status' || column.field === 'typeOfRequest') {
                        return _.each(response.data, function(filter) {
                            filter.description = $translate.instant(filter.code)
                        });
                    }
                    return filtersForColumn ? policingQueueFilterService.getFilters(column, filtersForColumn, response.data) : response.data;
                });
            },
            getErrors: function(caseId, queryParams) {
                return $http.get('api/policing/queue/errors/' + caseId, {
                        params: {
                            params: JSON.stringify(queryParams)
                        }
                    })
                    .then(function(response) {
                        return response.data;
                    });
            },
            releaseSelected: function(records) {
                return $http.post('api/policing/queue/admin/release', getRecordIds(records));
            },
            holdSelected: function(records) {
                return $http.post('api/policing/queue/admin/hold', getRecordIds(records));
            },
            releaseAll: function(type, queryParams) {
                return $http.put('api/policing/queue/admin/release/' + ensureValid(type), JSON.stringify(queryParams));
            },
            holdAll: function(type, queryParams) {
                return $http.put('api/policing/queue/admin/hold/' + ensureValid(type), JSON.stringify(queryParams));
            },
            deleteSelected: function(records) {
                return $http.post('api/policing/queue/admin/delete', getRecordIds(records));
            },
            deleteAll: function(type, queryParams) {
                return $http.post('api/policing/queue/admin/delete/' + ensureValid(type), JSON.stringify(queryParams));
            },
            editNextRunTime: function(nextRunTime, records) {
                return $http.post('api/policing/queue/admin/editNextRuntTime/' + nextRunTime, getRecordIds(records));
            },
            config: function(config) {
                return angular.extend(defaultConfig, config);
            }
        };
    });
