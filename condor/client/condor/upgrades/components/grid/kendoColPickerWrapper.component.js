(function() {

    var colPicker = {
        controllerAs: 'vmw',
        bindings: {
            gridOptions: '='
        },
        controller: function() {

            this.$onInit = function() {}
        }
    };

    angular.module('inprotech.components.form').component('ipKendoColPickerWrapper', angular.extend({}, colPicker, {
        template: '<ip-kendo-column-picker data-grid-options="vmw.gridOptions"></ip-kendo-column-picker>'
    }));
})();