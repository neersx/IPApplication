(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('caseFamiliesApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/caseFamilies'), {});
            }
        ]);
})();
