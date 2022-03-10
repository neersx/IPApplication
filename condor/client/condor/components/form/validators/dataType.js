angular.module('inprotech.components.form').directive('ipDataType', function() {
    'use strict';

    var INTEGER_REGEXP = /^\-?\d+$/;
    var DECIMAL_REGEXP = /^\-?\d+(\.\d+)?$/;
    var POSITIVEINTEGER_REGEXP = /^[1-9][0-9]*$/;
    var NON_NEGATIVE_INTEGER_REGEXP = /^[0-9]*$/;

    return {
        restrict: 'A',
        require: 'ngModel',
        link: function(scope, elm, attrs, ctrl) {
            'use strict';

            var dataType = attrs.ipDataType.toLowerCase();
            var tagName = elm.prop("tagName").toLowerCase();

            ctrl.$validators[dataType] = function(modelValue, viewValue) {
                return isValid(viewValue);
            };

            ctrl.$parsers.push(function(viewValue) {
                if (isValid(viewValue)) {
                    return parse(viewValue);
                }

                return viewValue;
            });

            function isValid(viewValue) {
                var value = getViewValue(viewValue);

                if (ctrl.$isEmpty(value)) {
                    return true;
                }

                switch (dataType) {
                    case 'integer':
                        return INTEGER_REGEXP.test(value);
                    case 'decimal':
                        return DECIMAL_REGEXP.test(value);
                    case 'positiveinteger':
                        return POSITIVEINTEGER_REGEXP.test(value);
                    case 'nonnegativeinteger':
                        return NON_NEGATIVE_INTEGER_REGEXP.test(value);
                }

                return true;
            }

            function getViewValue(value) {
                if (!value) {
                    return null;
                }

                if (tagName === 'ip-text-dropdown-group') {
                    return value[attrs.textField || 'text'];
                }

                return value;
            }

            function parse(viewValue) {
                if (tagName === 'ip-text-dropdown-group') {
                    var v;
                    switch (dataType) {
                        case 'positiveinteger':
                        case 'integer':
                        case 'nonnegativeinteger':
                            v = normalise(parseInt(getViewValue(viewValue)));
                            break;
                        case 'decimal':
                            v = normalise(parseFloat(getViewValue(viewValue)));
                            break;
                    }

                    var obj = angular.extend({}, viewValue);
                    obj[attrs.textField || 'text'] = v;

                    return obj;
                } else {
                    switch (dataType) {
                        case 'positiveinteger':
                        case 'integer':
                        case 'nonnegativeinteger':
                            return normalise(parseInt(getViewValue(viewValue)));
                        case 'decimal':
                            return normalise(parseFloat(getViewValue(viewValue)));
                    }
                }

                return viewValue;
            }

            function normalise(val) {
                if (val == null) {
                    return null;
                } else if (isNaN(val)) {
                    return null;
                }

                return val;
            }
        }
    };
});
