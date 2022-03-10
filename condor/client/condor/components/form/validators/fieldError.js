angular.module('inprotech.components.form').directive('ipFieldError', function() {
    'use strict';

    return {
        restrict: 'A',
        require: 'ngModel',
        link: function(scope, elm, attrs, ngModel) {
            setError(attrs.ipFieldError);

            attrs.$observe('ipFieldError', setError);

            ngModel.$viewChangeListeners.push(function() {
                //todo: this is walkaround for text fields used in restmod. It should be removed after we get rid of restmod.
                if (ngModel.$fieldError) {
                    ngModel.$setValidity('fieldError', null);
                    ngModel.$fieldError = null;
                }
            });

            function setError(err) {
                if (err) {
                    ngModel.$setValidity('fieldError', false);
                    ngModel.$fieldError = attrs.ipFieldError;
                } else {
                    ngModel.$setValidity('fieldError', null);
                    ngModel.$fieldError = null;
                }
            }
        }
    };
});