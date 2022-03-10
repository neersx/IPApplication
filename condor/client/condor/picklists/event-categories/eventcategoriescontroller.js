(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('eventCategoriesController', function($scope) {
            var c = this;

            $scope.vm.updateListItemFromMaintenance = function(listItem, maintenanceItem){
                listItem.name = maintenanceItem.name;
                listItem.description = maintenanceItem.description;
                listItem.imageDescription = maintenanceItem.imageData.description;
                listItem.image = maintenanceItem.imageData.image;
            };

            c.eventCategoryImages = {
                extendQuery: function(query) {
                    var extended = angular.extend({}, query, {
                        isUsedByEventCategory: true
                    });
                    return extended;
                }
            };

            var clearWatch = $scope.$watch('vm.entry', function(entry) {
                if (entry) {
                    if ($scope.vm.maintenanceState === 'duplicating') {
                        entry.name += ' - Copy';
                        setFormDirty();
                    }
                }
                clearWatch();
            });

            function setFormDirty() {
                $scope.vm.maintenance.$setDirty();
            }
        });
})();
