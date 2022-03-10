angular.module('inprotech.components.form')
    .directive('ipDatepicker', function (dateService, formControlHelper, $filter, $timeout) {
        'use strict';

        return {
            require: ['ngModel', '?^ipForm'],
            restrict: 'E',
            templateUrl: function (e, attr) {
                if (attr.columnFilter) {
                    return 'condor/components/form/grid-column-filter-datepicker.html';
                }

                return 'condor/components/form/datepicker.html';
            },
            scope: {
                label: '@?',
                isDisabled: '=?',
                readonly: '=?',
                onBlur: '&?',
                onBlurNg: '&?',
                date: '=ngModel',
                earlierThan: '=?',
                laterThan: '=?',
                includeSameDate: '@?',
                isSaved: '=?',
                isDirty: '&?',
                inlineDataItemId: '@?',
                noEditState: '=?',
                useLocalTimezone: '<',
                onChange: '&?'
            },
            controller: function ($scope) {
                var config = {
                    picker: {
                        opened: false,
                        options: {
                            showWeeks: false
                        },
                        dateFormat: dateService.dateFormat,
                        parseFormats: dateService.getParseFormats()
                    },
                    isDisabled: $scope.isDisabled || false,
                    readonly: $scope.readonly || false,
                    date: $scope.date || null,
                    earlierThan: $scope.earlierThan || null,
                    laterThan: $scope.laterThan || null,
                    includeSameDate: ($scope.includeSameDate === 'true'),
                    isSaved: $scope.isSaved || false,
                    onBlur: $scope.onBlur || angular.noop,
                    inlineDataItemId: $scope.inlineDataItem || null,
                    onChange: $scope.onChange || angular.noop
                };

                angular.extend($scope, config);
            },
            link: function (scope, element, attrs, ctrls) {
                var ngModelCtrl = ctrls[0];
                var formCtrl = ctrls[1];
                var showDateParseError = false;

                scope.uid = scope.$id;

                formControlHelper.legacyInit({
                    model: ngModelCtrl,
                    form: formCtrl,
                    onReset: function () {
                        scope.date = null;
                        scope.form.datepicker.$setPristine();
                    }
                });

                if (attrs.hasOwnProperty('ipRequired') || attrs.hasOwnProperty('required')) {
                    element.find('.input-wrap').addClass('required');
                }

                if (!scope.isDirty) {
                    scope.isDirty = function () {
                        return scope.form.datepicker.$dirty;
                    };
                }

                scope.$watch('laterThan', function () {
                    if (scope.laterThan) {
                        if (!scope.date) {
                            ngModelCtrl.$resetErrors();
                            scope.form.datepicker.$setPristine();
                        } else {
                            ngModelCtrl.$setValidity('minDateValidation', (scope.includeSameDate) ? scope.laterThan <= scope.date : scope.laterThan < scope.date);
                        }
                    } else {
                        ngModelCtrl.$resetErrors();
                    }
                });

                scope.$watch('earlierThan', function () {
                    if (scope.earlierThan) {
                        if (!scope.date) {
                            ngModelCtrl.$resetErrors();
                            scope.form.datepicker.$setPristine();
                        } else {
                            ngModelCtrl.$setValidity('maxDateValidation', (scope.includeSameDate) ? scope.earlierThan >= scope.date : scope.earlierThan > scope.date);
                        }
                    } else {
                        ngModelCtrl.$resetErrors();
                    }
                });

                scope.open = function () {
                    scope.picker.opened = !scope.picker.opened;
                };

                scope.blur = function () {
                    $timeout(function () {
                        var isDateValid = moment.isDate(ngModelCtrl.$viewValue)
                        if (isDateValid) {
                            ngModelCtrl.$viewValue = dateService.adjustTimezoneOffsetDiff(ngModelCtrl.$viewValue);
                            if (!scope.picker.opened) {
                                var triggerFormat = angular.copy(ngModelCtrl.$viewValue);
                                ngModelCtrl.$setViewValue(triggerFormat);
                            }

                            ngModelCtrl.$setTouched();
                            if (scope.laterThan) {
                                if (!scope.date) {
                                    ngModelCtrl.$resetErrors();
                                    scope.form.datepicker.$setPristine();
                                } else {
                                    ngModelCtrl.$setValidity('minDateValidation', (scope.includeSameDate) ? scope.laterThan <= scope.date : scope.laterThan < scope.date);
                                }
                            }
                            if (scope.earlierThan) {
                                if (!scope.date) {
                                    ngModelCtrl.$resetErrors();
                                    scope.form.datepicker.$setPristine();
                                } else {
                                    ngModelCtrl.$setValidity('maxDateValidation', (scope.includeSameDate) ? scope.earlierThan >= scope.date : scope.earlierThan > scope.date);
                                }
                            }

                            if (scope.onBlur && scope.onBlur != angular.noop) {
                                scope.onBlur()(attrs.name, scope.date, scope.inlineDataItemId);
                            }
                            if (scope.onBlurNg && scope.onBlurNg != angular.noop) {
                                scope.onBlurNg()({ name: attrs.name, date: scope.date, dataitem: scope.inlineDataItemId });
                            }

                        }
                    });
                };

                scope.showError = function () {
                    if (scope.isDisabled || (ngModelCtrl.$error.required && !ngModelCtrl.$touched)) {
                        return false;
                    }

                    return (scope.form.$invalid && showDateParseError) || ngModelCtrl.$invalid;
                };

                var fieldErrors = ['required', 'ipRequired', 'date', 'laterThanDate', 'equalLaterThanDate', 'equalEarlierThanDate', 'earlierThanDate'];
                scope.getError = function () {
                    if (!ngModelCtrl.$error && !scope.form.$error) {
                        return null;
                    }

                    var keys = _.union(
                        Object.keys(ngModelCtrl.$error) || [],
                        Object.keys(scope.form.$error) || []);

                    if (!keys.length) {
                        return null;
                    }

                    if (keys[0] === 'minDateValidation') {
                        scope.errorDate = $filter('date')(scope.laterThan, dateService.dateFormat, '+0000');
                        keys[0] = (scope.includeSameDate) ? 'equalLaterThanDate' : 'laterThanDate';
                    }

                    if (keys[0] === 'maxDateValidation') {
                        scope.errorDate = $filter('date')(scope.earlierThan, dateService.dateFormat, '+0000');
                        keys[0] = (scope.includeSameDate) ? 'equalEarlierThanDate' : 'earlierThanDate';
                    }

                    if (_.contains(fieldErrors, keys[0])) {
                        return 'field.errors.' + keys[0];
                    }
                    return keys[0];
                };

                function input() {
                    return element.find('input.datepicker-input');
                }

                input().on('keydown keypress', function ($event) {
                    if ([13, 9, 27].indexOf($event.which) >= 0) {
                        showDateParseError = true;
                        return;
                    }
                    showDateParseError = false;
                });

                input().on('focusout', function () {
                    showDateParseError = true;
                });

                element.on('setFocus', function () {
                    input().focus();
                });

                scope.$on('$destroy', function () {
                    element.off();
                });

                scope.onChange({selectedDate: this.date});
            }
        }
    });