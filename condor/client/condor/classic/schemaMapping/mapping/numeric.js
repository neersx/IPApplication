angular.module('Inprotech.SchemaMapping')
    .directive('inNumeric', function() {
        'use strict';
        return {
            scope: {
                numType: '&inNumeric'
            },
            require: 'ngModel',
            link: function(scope, elm, attrs, ctrl) {
                ctrl.$parsers.push(function(value) {
                    ctrl.$setValidity('numeric', true);

                    if (value === undefined || value === null) {
                        return;
                    }

                    var filtered = value.replace(/[^\d-+.]/, '');
                    if (filtered !== value) {
                        value = filtered;
                        ctrl.$setViewValue(value);
                        ctrl.$render();
                    }

                    if (ctrl.$isEmpty(value)) {
                        return value;
                    }

                    var decimal = /^[+-]?\d+(\.\d*)?$/;
                    var integer = /^[+-]?\d+$/;
                    
                    var operators = {
                        '<=': function(_){return _ <= 0;},
                        '>=': function(_){return _ >= 0;},
                        '<': function(_){return _ < 0;},
                        '>': function(_){return _ > 0;}
                    };

                    function compareToZero(comparer) {
                        var intVal = parseInt(value);
                        if (isNaN(intVal)) {
                            return false;
                        }

                        return operators[comparer](intVal);
                    }

                    function testValue(regex, comparer) {
                        var isValidSign = comparer ? compareToZero(comparer) : true; 

                        if (regex.test(value) && isValidSign) {
                            return value;
                        } else {
                            ctrl.$setValidity('numeric', false);
                            return undefined;
                        }
                    }

                    switch (scope.numType()) {
                        case 'Double':
                        case 'Float':
                        case 'Decimal':
                            return testValue(decimal);
                        case 'Long':
                        case 'Short':
                        case 'Byte':
                        case 'Int':
                        case 'Integer':
                            return testValue(integer);
                        case 'NonPositiveInteger':
                            return testValue(integer, '<=');
                        case 'NegativeInteger':
                            return testValue(integer, '<');
                        case 'PositiveInteger':
                            return testValue(integer, '>');
                        case 'NonNegativeInteger':
                        case 'UnsignedLong':
                        case 'UnsignedShort':
                        case 'UnsignedByte':
                        case 'UnsignedInt':
                            return testValue(integer, '>=');
                    }
                });
            }
        };
    });
