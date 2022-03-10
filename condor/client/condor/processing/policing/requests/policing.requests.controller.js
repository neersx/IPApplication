(function () {
    'use strict';

    angular.module('inprotech.processing.policing')
        .controller('ipPolicingSavedRequestsController', ipPolicingSavedRequestsController);

    ipPolicingSavedRequestsController.$inject = ['$scope', 'viewData'];

    function ipPolicingSavedRequestsController($scope, viewData) {
        'use strict';

        var vm = this;
        var topics;
        vm.$onInit = onInit;

        function onInit() {
            vm.viewData = viewData;

            topics = {
                requests: {
                    key: 'requests',
                    title: 'policing.management.sections.savedrequests',
                    template: '<ip-saved-request-view view-data="$topic.viewData" data-topic="$topic">',
                    viewData: vm.viewData
                }
            };
    
            vm.options = {
                topics: [topics.requests],
                actions: []
            };
        }        
    }

})();