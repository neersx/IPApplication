(function() {
    'use strict';

    angular.module('inprotech.components.notification')
        .run(function(modalService) {
            modalService.register('DiscardChanges', 'NotificationController', 'condor/components/notification/notificationservice/discardchanges.html', {
                windowClass: 'centered',
                backdropClass: 'centered'
            });

            modalService.register('Confirm', 'NotificationController', 'condor/components/notification/notificationservice/confirm.html', {
                windowClass: 'centered',
                backdropClass: 'centered',
                size: 'md'
            });

            modalService.register('ConfirmDelete', 'NotificationController', 'condor/components/notification/notificationservice/confirmDelete.html', {
                windowClass: 'centered',
                backdropClass: 'centered',
                size: 'md'
            });

            modalService.register('Alert', 'NotificationController', 'condor/components/notification/notificationservice/alert.html', {
                windowClass: 'centered modal-alert',
                backdropClass: 'centered',
                size: 'lg'
            });

            modalService.register('Info', 'NotificationController', 'condor/components/notification/notificationservice/info.html', {
                windowClass: 'centered',
                backdropClass: 'centered'
            });

            modalService.register('UnsavedChanges', 'NotificationController', 'condor/components/notification/notificationservice/unsavedchanges.html', {
                windowClass: 'centered',
                backdropClass: 'centered'
            });
        });

    angular.module('inprotech.components.notification')
        .controller('NotificationController',
            function($scope, $uibModalInstance, options, $timeout) {

                $scope.options = options;

                $scope.confirm = function(action) {
                    $uibModalInstance.close(action || 'Confirm');
                };

                $scope.cancel = function() {
                    $timeout(function() {
                        $uibModalInstance.dismiss('Cancel');                    
                    }, 0);                    
                };
            });
})();
