angular.module('Inprotech.CaseDataComparison')
    .factory('notificationsService', ['$location', 'http', '$q', 'url', function($location, http, $q, url) {
        'use strict';

        var isFilteredCaseList = function() {
            return $location.search().caselist || $location.search().ts;
        };
        
        var isFilteredExecution = function() {
            return $location.search().se != null || $location.search().dataSource != null;
        };

        var getNotifications = function(filterParams) {
            var q = $q.defer();

            var data = {
                pageSize: 50,
                since: filterParams.since,
                dataSourceTypes: filterParams.dataSources,
                includeReviewed: filterParams.includeReviewed,
                includeErrors: filterParams.includeErrors,
                includeRejected: filterParams.includeRejected,
                searchText: filterParams.searchText || ''
            };

            http.post(url.api('casecomparison/inbox/notifications'), data)
                .success(function(data) {
                    q.resolve(data);
                })
                .catch(function() {
                    q.resolve();
                });

            return q.promise;
        };

        var getCaseList = function(filterParams) {
            var q = $q.defer();

            var data = {
                pageSize: 50,
                since: filterParams.since,

                caselist: $location.search().caselist || '',
                ts: $location.search().ts || '',

                dataSourceTypes: filterParams.dataSources,
                includeReviewed: filterParams.includeReviewed,
                includeErrors: filterParams.includeErrors,
                includeRejected: filterParams.includeRejected,

                searchText: filterParams.searchText || ''
            };

            http.post(url.api('casecomparison/inbox/cases'), data)
                .success(function(data) {
                    q.resolve(data);
                })
                .catch(function() {
                    q.resolve();
                });

            return q.promise;
        };

        var getExecutionList = function(filterParams) {
            var q = $q.defer();

            var data = {
                pageSize: 50,
                since: filterParams.since,

                scheduleExecutionId: $location.search().se || '',
                dataSource: $location.search().dataSource || '',

                dataSourceTypes: filterParams.dataSources,
                includeReviewed: filterParams.includeReviewed,
                includeErrors: filterParams.includeErrors,
                includeRejected: filterParams.includeRejected,

                searchText: filterParams.searchText || ''
            };

            http.post(url.api('casecomparison/inbox/executions'), data)
                .success(function(data) {
                    q.resolve(data);
                })
                .catch(function() {
                    q.resolve();
                });

            return q.promise;
        };

        return {
            get: function(filterParams) {
                if (isFilteredCaseList()) {
                    return getCaseList(filterParams);
                } else if(isFilteredExecution()) {
                    return getExecutionList(filterParams);
                } else {
                    return getNotifications(filterParams);
                }
            },
            forSelectedCases: isFilteredCaseList,
            isFilteredExecution: isFilteredExecution
        };
    }]);