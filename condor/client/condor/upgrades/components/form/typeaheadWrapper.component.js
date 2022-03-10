(function() {

    var multiTemplate = '<ip-typeahead multiselect="true" id="{{vmw.id}}" data-config="{{vmw.config}}" ng-model="vmw.value" data-extend-query="vmw.extendQuery" ng-disabled="vmw.disabled" ng-required="vmw.required" picklist-can-maintain="vmw.picklistCanMaintain" external-scope="vmw.externalScope"></ip-typeahead>';

    var typeahead = {
        controllerAs: 'vmw',
        bindings: {
            id: '@',
            config: '<',
            extendQuery: '<?',
            value: '=',
            disabled: '<?',
            required: '<?',
            picklistCanMaintain: '<?',
            externalScope: '<?'
        },
        controller: function() {

            this.$onInit = function() {}
        }
    };

    angular.module('inprotech.components.form').component('ipTypeaheadWrapper', angular.extend({}, typeahead, {
        template: multiTemplate.replace('multiselect="true" ', '')
    }));

    angular.module('inprotech.components.form').component('ipTypeaheadMultiWrapper', angular.extend({}, typeahead, {
        template: multiTemplate
    }));
})();