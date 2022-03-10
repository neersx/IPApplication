angular.module('inprotech.configuration.general.validcombination')
    .component('ipActionOrderModalSubheader', {
        bindings: {
            allItems: '<',
            currentItem: '<',
            hasUnsavedChanges: '<',
            launchSrc: '<'
        },
        templateUrl: 'condor/configuration/general/validcombination/action/action-order-modal-subheader.html',
        controllerAs: 'vm',
        controller: function($scope) {
            var vm = this;

            vm.onNavigate = function(newItem) {
                $scope.$emit('modalChangeView', {
                    dataItem: newItem
                });
            };
        }
    });
