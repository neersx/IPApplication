angular.module('inprotech.components.modal').factory('maintenanceModalService', function() {
    'use strict';

    var self = {};

    function init($scope, $uibModalInstance, addItemFunc) {
        self.scope = $scope;
        self.uibModalInstance = $uibModalInstance;
        self.addItemFunc = addItemFunc;

        return {
            applyChanges: applyChanges
        };
    }

    return init;

    function applyChanges(data, options, isEditMode, isAddAnother, keepOpen) {
        if (isEditMode) {
            applyEdit(data, options, keepOpen);
        } else if (isAddAnother) {
            applyAddAnother(data, options);
        } else {
            applyAdd(data);
        }
    }

    function applyEdit(data, options, keepOpen) {
        angular.merge(options.dataItem, data);

        // fix merge not updating length of array data as expected
        Object.keys(data).forEach(function(k) {
            if (Array.isArray(data[k])) {
                options.dataItem[k].length = data[k].length;
            }
        });

        if (!keepOpen) {
            self.uibModalInstance.close();
        }
    }

    function applyAddAnother(data, options) {
        var newOptions = angular.extend({}, options, {
            isAddAnother: true
        });
        self.addItemFunc(data);

        self.scope.$emit('modalChangeView', newOptions);
    }

    function applyAdd(data) {
        self.uibModalInstance.close(data);
    }
});