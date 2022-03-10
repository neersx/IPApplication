angular.module('inprotech.components.form').factory('formControlHelper', function () {
    'use strict';

    return {
        //todo: remove this legacy init
        legacyInit: function (args) {
            var ngModel = args.model,
                formCtrl = args.form,
                onReset = args.onReset || angular.noop;

            if (ngModel) {
                ngModel.$reset = function () {
                    ngModel.$setViewValue(null);
                    ngModel.$setPristine();
                    ngModel.$setUntouched();
                    ngModel.$resetErrors();
                    onReset();
                };

                ngModel.$resetErrors = function () {
                    _.each(ngModel.$validatorExtensions, function (v) {
                        v.reset();
                    });

                    _.each(Object.keys(ngModel.$error), function (key) {
                        ngModel.$setValidity(key, null);
                    });
                };
            }

            if (formCtrl) {
                formCtrl.$addController(ngModel);
            }
        },

        reset: function (ngModel) {
            ngModel.$setViewValue(null);
            ngModel.$setUntouched();
            ngModel.$resetErrors();
        },

        // return first error
        getError: function (ngModel) {
            return function () {
                if (!ngModel) {
                    return null;
                }

                if (!ngModel.$error) {
                    return null;
                }

                var keys = Object.keys(ngModel.$error);

                if (!keys.length) {
                    return null;
                }

                if (ngModel.$fieldError) {
                    return ngModel.$fieldError;
                }

                return 'field.errors.' + keys[0];
            };
        },


        /*
            The following properties will be added to scope as interface to caller
            - disabled
            - model
            - getError   
            - change     
        */
        init: function (args) {
            var element = args.element,
                attrs = args.attrs,
                className = args.className,
                inputSelector = args.inputSelector || 'input',
                scope = args.scope,
                ngModel = args.ngModelCtrl,
                formCtrl = args.formCtrl,
                onReset = args.onReset || angular.noop,
                onChange = args.onChange || function () {
                    if (ngModel && ngModel.$invalid) {
                        ngModel.$resetErrors();
                    }
                },
                onRender = args.onRender || angular.noop;

            if (className) {
                element.addClass(className);
            }

            element.on('click', 'label', function () {
                element.find(inputSelector).focus();
            });

            element.on('setFocus', function () {
                element.find(inputSelector).focus();
            });

            attrs.$observe('disabled', function (val) {
                if (_.isBoolean(val)) {
                    scope.disabled = val;
                } else {
                    scope.disabled = val !== 'false';
                }
            });

            if (attrs.hasOwnProperty('disabled')) {
                scope.disabled = true;
            }

            if (ngModel) {
                if (!args.customRender) {
                    ngModel.$render = function () {
                        //todo: it's more flexible to set scope.model in callback
                        scope.model = ngModel.$viewValue;
                        onRender(scope.model);
                    };
                }

                if (!args.customChange) {
                    scope.change = function () {
                        onChange();
                        ngModel.$setViewValue(scope.model);
                    };
                }

                ngModel.$reset = function () {
                    ngModel.$setViewValue(null);
                    ngModel.$setPristine();
                    ngModel.$setUntouched();
                    ngModel.$resetErrors();
                    scope.model = null;
                    onReset();
                };

                ngModel.$resetErrors = function () {
                    _.each(ngModel.$validatorExtensions, function (v) {
                        v.reset();
                    });

                    _.each(Object.keys(ngModel.$error), function (key) {
                        ngModel.$setValidity(key, null);
                    });
                };
            }

            scope.getError = function () {
                if (!ngModel) {
                    return null;
                }

                if (!ngModel.$error) {
                    return null;
                }

                var keys = Object.keys(ngModel.$error);

                if (!keys.length) {
                    return null;
                }

                if (ngModel.$fieldError) {
                    return ngModel.$fieldError;
                }

                return 'field.errors.' + keys[0];
            };

            if (formCtrl) {
                formCtrl.$addController(ngModel);
            }

            if (scope.$on) {
                scope.$on('$destroy', function () {
                    element.off();
                });
            } else {
                scope.$onDestroy = function () {
                    element.off();
                };
            }
        },

        transcludeNgOptions: function (original) {
            return original.replace(/\s+in\s+(\S+)/, ' in $parent.$1');
        }
    };
});
