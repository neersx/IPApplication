(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('officesApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/offices'), {});
            }
        ]);
})();
