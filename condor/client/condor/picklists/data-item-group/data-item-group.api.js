(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('dataItemGroupApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/dataItemGroup'), {});
            }
        ]);
})();