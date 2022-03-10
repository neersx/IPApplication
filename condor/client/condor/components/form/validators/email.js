angular.module('inprotech.components.form').directive('ipEmail', function() {
    'use strict';

    return {
        restrict: 'A',
        require: 'ngModel',
        link: function(scope, elm, attr, ctrl) {
            
            var emailRegex = /^[_a-zA-Z0-9]+(\.[_a-zA-Z0-9]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$/;

            ctrl.$validators.ipEmail = function(modelValue, viewValue) {
                if (ctrl.$isEmpty(viewValue) && ctrl.$untouched) {
                    return true;
                }

                if (ctrl.$validators.ipEmail.forced) {
                    return emailRegex.test(viewValue);
                }
                return ctrl.$untouched || emailRegex.test(viewValue);
            };

            if (!ctrl.$validatorExtensions) {
                ctrl.$validatorExtensions = [];
            }

            ctrl.$validatorExtensions.push({
                reset: function() {
                    ctrl.$validators.ipEmail.forced = false;
                },
                force: function() {
                    ctrl.$validators.ipEmail.forced = true;
                }
            });
        }
    };
});