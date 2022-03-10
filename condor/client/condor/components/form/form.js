angular.module('inprotech.components.form').directive('ipForm', function() {
    'use strict';
    return {
        restrict: 'A',
        require: 'form',
        scope: true,
        controller: function($scope) {
            $scope.controllers = [];

            this.$addController = function(ctrl) {
                if (!_.contains($scope.controllers, ctrl)) {
                    $scope.controllers.push(ctrl);
                }
            };

            // todo: refine remove
            // this.$removeController = function(ctrl) {
            //     if (_.contains(controllers, ctrl)) {
            //         controllers = controllers.without(ctrl);
            //     }
            // };

            this.$update = function() {
                $scope.formCtrl.$loading = _.any($scope.controllers, function(c) {
                    if (c) {
                        return c.$loading
                    }
                });
            };
        },
        link: function(scope, element, attrs, formCtrl) {
            scope.formCtrl = formCtrl;
            formCtrl.$reset = function() {
                _.each(scope.controllers, function(ctrl) {
                    if (ctrl.$reset) {
                        ctrl.$reset();
                    }
                });
            };
            formCtrl.$resetErrors = function() {
                _.each(scope.controllers, function(ctrl) {
                    if (ctrl.$resetErrors) {
                        ctrl.$resetErrors();
                    }
                });
            };
            formCtrl.$validate = function() {
                _.each(scope.controllers, function(ctrl) {
                    _.each(ctrl.$validatorExtensions, function(v) {
                        v.force();
                    });

                    ctrl.$validate();
                });

                return formCtrl.$valid;
            };
        }
    };
});
