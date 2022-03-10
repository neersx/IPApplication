
angular.module('inprotech.components.form')
    .filter('localeDate', ['$filter', 'dateService', function ($filter, dateService) {
        return function (value) {
            var dateValue = value instanceof Date && value.getTimezoneOffset() > 0 ? new Date(value.getTime() + value.getTimezoneOffset() * 60 * 1000) : value;
            var dateFormat = dateService.useDefault() ? 'shortDate' : dateService.dateFormat;
            return $filter('date')(dateValue, dateFormat);
        }
    }]);