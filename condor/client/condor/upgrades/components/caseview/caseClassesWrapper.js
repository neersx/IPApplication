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

    angular.module('inprotech.components.form').component('ipCaseviewClassesWrapper', angular.extend({}, caseActions, {
        template: '<ip-caseview-classes view-data="vmw.topic.params.viewData" enable-rich-text="vmw.topic.params.enableRichText" data-screen-criteria-key="vmw.topic.params.screenCriteriaKey" data-topic="vmw.topic" data-is-external="vmw.topic.params.isExternal" data-show-web-link="vmw.topic.params.showWebLink"></ip-caseview-classes>'
    }));

})();