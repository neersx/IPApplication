(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('tagsController', function($http, $scope, notificationService, $translate) {
            $scope.vm.updateListItemFromMaintenance = function(listItem, maintenanceItem) {
                listItem.tagName = maintenanceItem.tagName;
            };

            $scope.vm.confirmAfterSave = function(entry, afterSaveResponse, callback) {
                if (entry.$response.data.result === 'confirmation') {
                    notificationService.confirm({
                        message: $translate.instant('picklist.tags.TagsConfirmation.update', {
                            tagName: entry.tagName
                        }),
                        cancel: 'No',
                        continue: 'Replace'
                    }).then(function() {
                        $http.put('api/picklists/tags/' + 'updateconfirm', entry).then(function() {
                            afterSaveResponse.rerunSearch = true;
                            callback($scope.vm, afterSaveResponse);
                        })
                    });
                } else {
                    callback($scope.vm, afterSaveResponse);
                }
            }
        });
})();