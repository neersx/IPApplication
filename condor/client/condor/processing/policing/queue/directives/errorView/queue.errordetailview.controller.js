(function() {
    'use strict';

    angular.module('inprotech.processing.policing')
        .controller('ipQueueErrordetailviewController', ipQueueErrordetailviewController);

    ipQueueErrordetailviewController.$inject = ['$scope', 'queueErrorViewHelper', 'kendoGridBuilder', 'policingQueueService', 'modalService'];

    function ipQueueErrordetailviewController($scope, queueErrorViewHelper, kendoGridBuilder, policingQueueService, modalService) {
        $scope.policingQueueService = policingQueueService;

        function read(queryParams) {
            return policingQueueService.getErrors($scope.parent.caseId, queryParams);
        }

        var gridParams = {
            'id': 'errordetail',
            'dateFormat': policingQueueService.config().dateFormat,
            'permissions': policingQueueService.config().permissions,
            'pageable': {
                pageSize: 10
            },
            'resizable': false,
            'scrollable': true,
            'read': read
        };
        $scope.errorDetailGridOptions = queueErrorViewHelper.buildOptionsForPolicingError(kendoGridBuilder, $scope, gridParams);
        $scope.errorDetailGridOptions.onSelect = function() {
            $scope.errorDetailGridOptions.clickHyperlinkedCell();
        };

        $scope.dismissAll = function() {
            $scope.$emit('RefreshOnHold', false);
            modalService.close('PolicingQueueErrors');
        };
    }
})();
