(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('instructionTypesApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/instructionTypes'), {});
            }
        ]);
})();
