(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('keywordsApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/keywords'), {});
            }
        ]);
})();
