(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .factory('datesOfLawApi', ['restmod', 'mixinsForPicklists', '$translate',
            function(restmod, mixinsForPicklists, $translate) {
                return mixinsForPicklists(restmod.model('/datesoflaw'), {
                    confirmDeleteMessage: $translate.instant('picklist.dateoflaw.confirmDelete1') + '</br>' +  $translate.instant('picklist.dateoflaw.confirmDelete2')
                });
            }
        ]);
})();
