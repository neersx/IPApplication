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

    angular.module('inprotech.components.form').component('ipCaseviewImagesWrapper', angular.extend({}, caseActions, {
        template: '<ip-case-view-images view-data="vmw.topic.params.viewData" data-topic="vmw.topic"></ip-case-view-images>'
    }));

})();