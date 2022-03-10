(function() {

    var caseActions = {
        controllerAs: 'vmw',
        bindings: {
            topic: '='
        },
        controller: function() {
            this.$onInit = function() {}
        }
    };

    angular.module('inprotech.components.form').component('ipCaseviewDesignatedCountriesWrapper', angular.extend({}, caseActions, {
        template: '<ip-case-view-designations view-data="vmw.topic.params.viewData" data-topic="vmw.topic" data-ipp-availability="vmw.topic.params.ippAvailability" data-show-web-link="vmw.topic.params.showWebLink"></ip-case-view-designations>'
    }));

})();