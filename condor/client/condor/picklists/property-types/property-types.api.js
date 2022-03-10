(function() {
    'use strict';

    angular.module('inprotech.picklists')        
        .factory('propertyTypesApi', ['restmod', 'mixinsForPicklists',
            function(restmod, mixinsForPicklists) {
                return mixinsForPicklists(restmod.model('/propertyTypes'), {});
            }
        ]);
})();