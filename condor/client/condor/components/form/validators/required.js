angular.module('inprotech.components.form').directive('ipRequired', function() {
    'use strict';

    return {
        restrict: 'A',
        require: 'ngModel',
        link: function(scope, elm, attr, ctrl) {
            var requiredFlag = attr.ipRequired === '' ? true : scope.$eval(attr.ipRequired);

            if (!requiredFlag) {
                return;
            }
            elm.attr('ip-required-flag', true);

            ctrl.$validators.ipRequired = function(modelValue, viewValue) {
                if (ctrl.$validators.ipRequired.forced) {
                    return !ctrl.$isEmpty(viewValue);
                }
                return ctrl.$untouched || !ctrl.$isEmpty(viewValue);
            };

            if (!ctrl.$validatorExtensions) {
                ctrl.$validatorExtensions = [];
            }

            ctrl.$validatorExtensions.push({
                reset: function() {
                    ctrl.$validators.ipRequired.forced = false;
                },
                force: function() {
                    ctrl.$validators.ipRequired.forced = true;
                }
            });
        }
    };
});
