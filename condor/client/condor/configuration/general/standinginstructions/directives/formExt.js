angular.module('inprotech.configuration.general.standinginstructions').directive('formExt', [function() {
    'use strict';
    return {
        restrict: 'AE',
        require: '^form',
        link: function(scope, element, attrs, ngForm) {
            ngForm.reset = function() {
                _.each(ngForm, function(c) {
                    if (c && c.reset) {
                        c.reset();
                    }
                });
                ngForm.$setPristine();
                ngForm.$setUntouched();
            };

            ngForm.setSavedValues = function() {
                _.each(ngForm, function(c) {
                    if (c && c.setNewValue) {
                        c.setNewValue();
                    }
                });
                ngForm.$setPristine();
                ngForm.$setUntouched();
            };

            ngForm.savable = function() {
                return ngForm.isDirty() && ngForm.$valid;
            };

            ngForm.isDirty = function() {
                var isDirty = false;
                _.each(ngForm, function(c) {
                    if (!c || c.$name === 'si.form') {
                        return false;
                    }
                    if (c) {
                        isDirty = isDirty || (c.$dirty ? c.$dirty : false);
                    }
                });

                return isDirty;
            };

        }
    };
}]);
