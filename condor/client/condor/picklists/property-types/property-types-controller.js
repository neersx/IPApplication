(function() {
    'use strict';

    angular.module('inprotech.picklists')
        .controller('propertyTypesController', ['$scope', '$translate', function($scope, $translate) {
            $scope.vm.updateListItemFromMaintenance = function(listItem, maintenanceItem) {
                listItem.key = maintenanceItem.key;
                listItem.code = maintenanceItem.code;
                listItem.value = maintenanceItem.value;
                listItem.allowSubClass = maintenanceItem.allowSubClass;
                listItem.crmOnly = maintenanceItem.crmOnly;
                listItem.image = maintenanceItem.imageData ? maintenanceItem.imageData.key : null;
            };
            var c = this;
            c.propertyTypeImages = {
                extendQuery: function(query) {
                    var extended = angular.extend({}, query, {
                        isUsedByPropertyTypes: true
                    });
                    return extended;
                }
            };

            c.subClassType = [{
                    key: '0',
                    value: $translate.instant('picklist.propertytype.doNotAllowSubClass')
                },
                {
                    key: '1',
                    value: $translate.instant('picklist.propertytype.allowSubClass')
                },
                {
                    key: '2',
                    value: $translate.instant('picklist.propertytype.allowSubClassAndItems')
                }
            ];

            if ($scope.vm.entry) {
                $scope.vm.entry.allowSubClass = $scope.vm.entry.allowSubClass ? $scope.vm.entry.allowSubClass.toString() : '0';
            }
        }])
})();