(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('instructionsApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/instructions'), {});
            }
        ]);
})();
