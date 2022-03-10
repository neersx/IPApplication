angular.module('inprotech.configuration.general.jurisdictions')
    .component('ipGroupModalSubheader', {
        bindings: {
            allItems: '<',
            currentItem: '<',
            isEditMode: '<',
            onNavigate: '<',
            hasUnsavedChanges: '<'
        },
        templateUrl: 'condor/configuration/general/jurisdictions/maintenance/directives/group-modal-subheader.html',
        controllerAs: 'vm',
        controller: function($scope) {
            var vm = this;

            vm.onNavigateInteral = function(newItem) {
                if (vm.onNavigate()) {
                    $scope.$emit('modalChangeView', {
                        dataItem: newItem
                    });
                }
            };
        }
    });