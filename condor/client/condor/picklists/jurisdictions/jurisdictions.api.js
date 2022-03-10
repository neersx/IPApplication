(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('jurisdictionsApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/jurisdictions'), {});
            }
        ]);
})();
