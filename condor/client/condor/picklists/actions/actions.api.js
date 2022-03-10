(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('actionsApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/actions'), {});
            }
        ]);
})();
