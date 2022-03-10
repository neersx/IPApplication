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

    angular.module('inprotech.components.form').component('ipCaseviewNamesWrapper', angular.extend({}, caseActions, {
        template: '<ip-caseview-names view-data="vmw.topic.params.viewData" data-screen-criteria-key="vmw.topic.params.screenCriteriaKey" data-topic="vmw.topic" data-is-external="vmw.topic.params.isExternal" data-show-web-link="vmw.topic.params.showWebLink"></ip-caseview-names>'
    }));

})();