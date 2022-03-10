angular.module('inprotech.configuration.general.jurisdictions').factory('jurisdictionBusinessDaysService', function($http) {
    'use strict';
    var baseUrl = 'api/configuration/jurisdictions/';

    var service = {
        search: function(queryParams, id) {
            return $http.get(baseUrl + 'maintenance/days/' + encodeURIComponent(id), {
                params: {
                    params: JSON.stringify(queryParams)
                }
            }).then(function(response) {
                return response.data;
            });
        },
        getCountryHolidayById: function(id, holidayId){
            return $http.get(baseUrl + 'maintenance/days/' + encodeURIComponent(id) + '/' +  encodeURIComponent(holidayId)
            ).then(function(response) {
                return response.data;
            });
        },
        getDayOfWeek: function(date) {
            var dateString = date.toDateString("yyyy-MM-dd");
            return $http.get(baseUrl + 'maintenance/dayofweek/' + dateString).then(function(response) {
                return response.data;
            });
        },
        deleteCountryHolidays: function(data){
            return $http.post(baseUrl + 'holidays/delete', data);
        },
        saveCountryHolidays: function(data){
            return $http.post(baseUrl + 'holidays/save', data);
        },
        isDuplicated: function (data) {
            return $http.get(baseUrl + 'holidays/duplicate', {
                params: {
                    params: data
                }
            });
        }
    }

    return service;
});