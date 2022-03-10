angular.module('inprotech.components.grid').component('ipKendoGridWrapper', {
    controllerAs: 'vmw',
    bindings: {
        gridOptions: '=',
        id: '@',
        searchHint: '@',
        showAdd: '=?',
        addItemName: '@',
        onAddClick: '&',
        addDisabled: '<?'
    },
    template: '<ip-kendo-grid data-grid-options="vmw.gridOptions" search-hint="vmw.searchHint" show-add="vmw.showAdd" add-item-name="{{vmw.addItemName | translate}}" on-add-click="vmw.onAddClick()"></ip-kendo-grid>',
    controller: ['$scope', 'kendoGridBuilder', function($scope, kendoGridBuilder) {

        this.$onInit = function() {
            $scope.vm = this.gridOptions.context;
            this.gridOptions = kendoGridBuilder.buildOptions($scope, this.gridOptions);
            if (!this.onAddClick) {
                this.onAddClick = function() {}
            }
        }
    }]
});