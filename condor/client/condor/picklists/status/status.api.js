(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('statusesApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/status'), {});
            }
        ]);
})();
