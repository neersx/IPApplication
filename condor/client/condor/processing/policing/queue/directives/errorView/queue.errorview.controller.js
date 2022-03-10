(function () {
    'use strict';

    angular.module('inprotech.processing.policing')
        .controller('ipQueueErrorviewController', ipQueueErrorviewController);

    ipQueueErrorviewController.$inject = ['$scope', 'queueErrorViewHelper', 'kendoGridBuilder', 'policingQueueService', 'modalService'];

    function ipQueueErrorviewController($scope, queueErrorViewHelper, kendoGridBuilder, policingQueueService, modalService) {
        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            vm.parent = $scope.parent;
            initGridOptions();
        }

        function read() {
            vm.totalErrorCount = vm.parent.error.totalErrorItemsCount;
            return vm.parent.error.errorItems;
        }

        var gridParams = {
            'id': 'error',
            'dateFormat': policingQueueService.config().dateFormat,
            'permissions': policingQueueService.config().permissions,
            'pageable': false,
            'resizable': false,
            'scrollable': true,
            'read': read
        };


        vm.viewErrors = function () {
            $scope.$emit('RefreshOnHold', true);
            modalService.open('PolicingQueueErrors', $scope);
        };

        function initGridOptions() {
            var errorGridOptions = queueErrorViewHelper.buildOptionsForPolicingError(kendoGridBuilder, $scope, gridParams);
            errorGridOptions.onSelect = function () {
                errorGridOptions.clickHyperlinkedCell();
            };
            vm.errorGridOptions = errorGridOptions;
        }        
    }
})();
