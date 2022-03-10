(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('casesApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/cases'), {});
            }
        ]);
})();
