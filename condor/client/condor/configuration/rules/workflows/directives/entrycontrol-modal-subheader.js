angular.module('inprotech.configuration.rules.workflows')
    .component('ipWorkflowsEntrycontrolModalSubheader', {
        bindings: {
            criteriaNumber: '<',
            entryDescription: '<',
            allItems: '<',
            currentItem: '<',
            isEditMode: '<',
            onNavigate: '<'
        },
        templateUrl: 'condor/configuration/rules/workflows/directives/entrycontrol-modal-subheader.html',
        controllerAs: 'vm',
        controller: function($scope) {
            var vm = this;

            vm.onNavigateInternal = function(newItem) {
                if(vm.onNavigate()) {
                    $scope.$emit('modalChangeView', {
                        dataItem: newItem
                    });
                }
            };
        }
    });
