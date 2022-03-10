(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('nametypegroupController', function($http, $scope) {
            $scope.vm.confirmAfterSave = function(entry, afterSaveResponse, callback) {
                if (entry.$response.data.result === 'success') {
                    afterSaveResponse.rerunSearch = true;
                    callback($scope.vm, afterSaveResponse);
                } else {
                    callback($scope.vm, afterSaveResponse);
                }
            }
        });
})();