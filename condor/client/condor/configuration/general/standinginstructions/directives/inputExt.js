angular.module('inprotech.configuration.general.standinginstructions').directive('inputExt', [function() {
    'use strict';
    return {
        restrict: 'A',
        require: '?ngModel',
        scope: {
            onValueChange: '&',
            validatorFuncs: '='
        },
        link: function(scope, element, attrs, ngModel) {
            if (!ngModel) {
                return;
            }

            var init = function() {
                angular.forEach(scope.validatorFuncs, function(value, key) {
                    ngModel.$validators[key] = value;
                });
            };

            var oldValue = '';

            function trackOldValue(value) {
                ngModel.$setPristine();
                oldValue = value;
                return value;
            }

            function handleViewValueChange() {
                if (ngModel.$viewValue === oldValue) {
                    ngModel.$setPristine();
                    scope.onValueChange({
                        isReverted: true
                    });
                    return;
                }
                scope.onValueChange({
                    isReverted: false
                });
            }

            ngModel.reset = function() {
                ngModel.$setViewValue(oldValue);
                ngModel.$commitViewValue();
                ngModel.$render();
            };

            ngModel.setNewValue = function() {
                var self = this;
                trackOldValue.call(self, ngModel.$viewValue);
            };

            ngModel.setIfDirty = function() {
                if (ngModel.$viewValue === oldValue) {
                    ngModel.$setPristine();
                } else {
                    ngModel.$setDirty(true);
                }
            };

            ngModel.resetErrors = function() {
                _.each(_.keys(ngModel.$error), function(e) {
                    ngModel.$setValidity(e, true);
                });
            };

            ngModel.markDeleted = function(revert) {
                if (revert) {
                    ngModel.$validate();
                    ngModel.setIfDirty();
                } else {
                    ngModel.resetErrors();
                    ngModel.$setDirty();
                }
            };

            ngModel.$formatters.push(trackOldValue);
            ngModel.$viewChangeListeners.push(handleViewValueChange);
            init();
        }
    };
}]);
