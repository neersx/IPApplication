//This directive is used for extending ngModel to support extra helper functions like
//- $oldValue. You can access old unsaved value as opposed to current binding model value. e.g. form.input.$oldValue
angular.module('Inprotech.Infrastructure').directive('inModelExtension', [function() {
    'use strict';

    return {
        restrict: 'A',
        require: '?ngModel',
        link: function(scope, element, attrs, ngModel) {
            if (!ngModel) {
                return;
            }
            var initialised;

            ngModel.$formatters.push(function(value) {
                if (!initialised) {
                    ngModel.$oldValue = value;
                    initialised = true;
                }

                return value;
            });

            var oldSetPristine = ngModel.$setPristine;
            ngModel.$setPristine = function() {
                oldSetPristine.apply(ngModel);
                ngModel.$oldValue = ngModel.$modelValue;
            };
        }
    };
}]);