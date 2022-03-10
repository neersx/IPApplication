//todo: rename this component to be more specific to kendo grid
angular.module('inprotech.components.buttons').component('ipKendoToggleDeleteButton', {
    template: '<ip-icon-button ng-click="vm.model.deleted=!vm.model.deleted" class="btn-no-bg" button-icon="{{vm.model.deleted ? \'trash\' : \'trash-o\'}}" ip-tooltip="{{ (vm.model.deleted ? \'Restore\' : \'Delete\') | translate }}"></ip-icon-button>',
    bindings: {
        model: '<',
        hasDetail: '@'
    },
    controllerAs: 'vm',
    controller: function ($scope, $element) {
        var vm = this;
        var hasDetail;
        vm.$onInit = onInit;

        function onInit() {
            hasDetail = vm.hasDetail === 'true';
        }

        $scope.$watch('vm.model.deleted', function (deleted, oldVal) {
            if (deleted === oldVal) {
                return;
            }

            var row = $element.parents('tr');
            if (deleted) {
                row.addClass('deleted');
                var grid = $element.parents('[kendo-grid]').data('kendoGrid');
                grid.collapseRow(row);

                if (hasDetail) {
                    row.find('.k-hierarchy-cell a').on('click', disableExpand);
                }
            } else {
                row.removeClass('deleted');

                if (hasDetail) {
                    row.find('.k-hierarchy-cell a').off('click', disableExpand);
                }
            }
        });

        function disableExpand(e) {
            e.stopPropagation();
            e.preventDefault();
            return false;
        }
    }
});
