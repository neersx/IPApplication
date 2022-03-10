(function() {

    var caseSummary = {
        controllerAs: 'vmw',
        bindings: {
            topic: '='
        },
        controller: function() {
            this.$onInit = function() {}
        }
    };

    angular.module('inprotech.components.form').component('ipCaseviewSummaryWrapper', angular.extend({}, caseSummary, {
        template: '<ip-caseview-summary view-data="vmw.topic.params.viewData" data-topic="vmw.topic" screen-control="vmw.topic.params.screenControl" with-image="vmw.topic.params.withImage && !vmw.topic.params.screenControl.imageKey.hidden" is-external="vmw.topic.params.isExternal" show-web-link="vmw.topic.params.showWebLink" has-screen-control="vmw.topic.params.hasScreenControl"></ip-caseview-summary>'
    }));

})();