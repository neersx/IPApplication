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

    angular.module('inprotech.components.form').component('ipCaseviewEventsWrapper', angular.extend({}, caseActions, {
        template: '<ip-case-view-events event-type="{{ vmw.topic.params.eventType }}" view-data="vmw.topic.params.viewData" data-topic="vmw.topic"></ip-case-view-events>'
    }));

})();