angular.module('inprotech.configuration.rules.workflows')
    .component('ipWorkflowsEventcontrolModalSubheader', {
        bindings: {
            criteriaNumber: '<',
            eventNumber: '<',
            eventDescription: '<',
            allItems: '<',
            currentItem: '<',
            isEditMode: '<',
            onNavigate: '<'
        },
        templateUrl: 'condor/configuration/rules/workflows/directives/eventcontrol-modal-subheader.html',
        controllerAs: 'vm',
        controller: function($scope) {
            var vm = this;

            vm.onNavigateInteral = function(newItem) {
                if(vm.onNavigate()) {
                    $scope.$emit('modalChangeView', {
                        dataItem: newItem
                    });
                }
            };
        }
    });
