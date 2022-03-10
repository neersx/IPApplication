angular.module('Inprotech')
    .directive('ipCustomerNumber', function() {
        'use strict';
        return {
            restrict: 'A',
            require: 'ngModel',
            link: function($scope, $element, $attributes, controller) {
                var input = $element.find('input, textArea');
                var existing = $attributes.customerNumbers;
                var updateView = function(value) {
                    controller.$setViewValue(value);
                    $scope.$apply(controller.$render());
                };

                input.on('keydown', function(event) {
                    if ((event.keyCode == 32 || event.keyCode == 188) && controller.$viewValue && this.selectionStart >= controller.$viewValue.length) {
                        event.preventDefault();
                        var text = controller.$viewValue;
                        if (text) {
                            if (text.trim().match(/.*,$/)) {
                                return;
                            }
                            updateView(text.trim() + ', ');
                        }
                    }
                });

                controller.$validators.ipCustomerNumber = function(modelValue, viewValue) {
                    var customerNumbersRegex = /^(\d+(, )?)*$/;
                    if (controller.$isEmpty(viewValue) && controller.$untouched) {
                        return true;
                    }
                    if (controller.$validators.ipCustomerNumber.forced) {
                        return customerNumbersRegex.test(viewValue);
                    }
                    return controller.$untouched || customerNumbersRegex.test(viewValue);
                };

                controller.$validators.ipDuplicateCustomerNumber = function(modelValue, viewValue) {
                    if (controller.$isEmpty(viewValue) && controller.$untouched) {
                        return true;
                    }

                    var hasDuplicateNumbers = hasDuplicates(existing, viewValue);

                    if (controller.$validators.ipDuplicateCustomerNumber.forced) {
                        return !hasDuplicateNumbers;
                    }
                    return controller.$untouched || !hasDuplicateNumbers;
                };

                var hasDuplicates = function(existingNumbers, newNumbers) {
                    if (hasInputDuplicateNumbers(newNumbers)) {
                        return true;
                    }

                    return hasDuplicateNumbers(existingNumbers, newNumbers);
                };

                var hasInputDuplicateNumbers = function(newNumbers) {
                    if (!newNumbers) {
                        return false;
                    }

                    var newNumbersArr = _.filter(newNumbers.split(', '), function(n) {
                        return n.trim() !== '';
                    });
                    var unique = _.uniq(newNumbersArr);
                    return unique.length !== newNumbersArr.length;
                };

                var hasDuplicateNumbers = function(existingNumbers, newNumbers) {
                    if (!existingNumbers || !newNumbers) {
                        return false;
                    }
                    var a = _.filter(existingNumbers.split(', '), function(n) {
                        return n.trim() !== '';
                    });
                    var b = _.filter(newNumbers.split(', '), function(n) {
                        return n.trim() !== '';
                    });
                    var c = _.intersection(a, b);
                    return c.length !== 0;
                };

                if (!controller.$validatorExtensions) {
                    controller.$validatorExtensions = [];
                }

                controller.$validatorExtensions.push({
                    reset: function() {
                        controller.$validators.ipCustomerNumber.forced = false;
                    },
                    force: function() {
                        controller.$validators.ipCustomerNumber.forced = true;
                    }
                });
            }
        };
    });