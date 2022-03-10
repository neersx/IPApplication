angular.module('inprotech.configuration.general.sitecontrols').directive('iptDataType', function() {
    'use strict';

    var INTEGER_REGEXP = /^\-?\d+$/;
    var DECIMAL_REGEXP = /^\-?\d+(\.\d+)?$/;

    return {
        restrict: 'A',
        require: 'ngModel',
        scope: {
            dataType: '@iptDataType',
            parentModel: '='
        },
        link: function(scope, elm, attrs, ctrl) {
            var dataType = scope.dataType.toLowerCase();
            var name = attrs.name;

            ctrl.$validators.dataType = function(modelValue, viewValue) {
                scope.parentModel.hasError(name, !isValid(viewValue));

                return true;
            };

            ctrl.$parsers.push(function(viewValue) {
                if (ctrl.$isEmpty(viewValue)) {
                    return null;
                }

                if (isValid(viewValue)) {
                    switch (dataType) {
                        case 'integer':
                            return parseInt(viewValue);
                        case 'decimal':
                            return parseFloat(viewValue);
                    }
                }

                return viewValue;
            });

            function isValid(value) {
                if (ctrl.$isEmpty(value)) {
                    return true;
                }

                switch (dataType) {
                    case 'integer':
                        return INTEGER_REGEXP.test(value);
                    case 'decimal':
                        return DECIMAL_REGEXP.test(value);
                }

                return true;
            }
        }
    };
});
