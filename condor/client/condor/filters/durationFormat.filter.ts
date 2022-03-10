angular.module('inprotech.filters', []).filter('durationFormat', function($filter) {
    return function(secs, displaySeconds) {
        if (!secs) {
            return '';
        }
        return $filter('date')(new Date(0, 0, 0).setSeconds(secs), displaySeconds ? 'HH:mm:ss' : 'HH:mm');
    };
});