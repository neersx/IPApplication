(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('eventsApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/events'), {});
            }
        ]);
})();
