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

    angular.module('inprotech.components.form').component('ipCaseviewTextsWrapper', angular.extend({}, caseActions, {
        template: '<ip-case-view-case-texts view-data="vmw.topic.params.viewData" filters="vmw.topic.filters" enable-rich-text="vmw.topic.params.enableRichText" keep-spec-history="vmw.topic.params.keepSpecHistory" data-topic="vmw.topic"></ip-case-view-case-texts>'
    }));

})();