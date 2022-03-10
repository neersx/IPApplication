describe('Inprotech.SchemaMapping.inNumeric', function() {
    'use strict';
    var _scope, _compile, _element, _formValue;

    beforeEach(module('Inprotech.SchemaMapping'));

    beforeEach(inject(function($rootScope, $compile) {
        _compile = $compile;

        _scope = $rootScope.$new();

        _scope.type = 'Integer';

        _scope.values = {};

        _element = '<input class="form-control" name="value" in-numeric="current.underlyingType().dataType" ng-model="values[current.node.id]" type="text" ng-required="true">';

        var form = '<form name="nodeForm" novalidate>' + _element + '</form>';

        _compile(form)(_scope);

        _formValue = _scope.nodeForm.value;

        _scope.current = {
            node: {
                id: 1
            },
            isRequired: false,
            underlyingType: function() {
                return {
                    dataType: _scope.type
                };
            }
        };
    }));

    describe('initialisation', function() {
        it('should set numType to node data type', function() {
            _scope.type = 'Float';

            _element = _compile(_element)(_scope);

            _scope.$digest();

            expect(_element.isolateScope().numType()).toBe('Float');
        });
    });

    describe('filtering', function() {
        it('should replace invalid letters', function() {
            _formValue.$setViewValue('1a');

            expect(_formValue.$viewValue).toBe('1');
        });

        it('should replace invalid special characters', function() {
            _formValue.$setViewValue('1%');

            expect(_formValue.$viewValue).toBe('1');
        });

        it('should not replace numbers', function() {
            _formValue.$setViewValue('123a4');

            expect(_formValue.$viewValue).toBe('1234');
        });

        it('should not replace allowed special characters', function() {
            _formValue.$setViewValue('+-.');

            expect(_formValue.$viewValue).toBe('+-.');
        });

        it('should be valid after filtering', function() {
            _formValue.$setViewValue('1a');

            expect(_formValue.$valid).toBe(true);
        });
    });

    describe('number type validation', function() {
        it('should be valid for correct Decimal', function() {
            _scope.type = 'Decimal';

            _formValue.$setViewValue('1.1');

            expect(_formValue.$valid).toBe(true);
        });

        it('should be invalid for incorrect Decimal', function() {
            _scope.type = 'Decimal';

            _formValue.$setViewValue('1..1');

            expect(_formValue.$valid).toBe(false);
        });

        it('should be valid for correct Integer', function() {
            _scope.type = 'Integer';

            _formValue.$setViewValue('1');

            expect(_formValue.$valid).toBe(true);
        });

        it('should be invalid for incorrect Integer', function() {
            _scope.type = 'Integer';

            _formValue.$setViewValue('1.1');

            expect(_formValue.$valid).toBe(false);
        });

        it('should be valid for correct NonPositiveInteger', function() {
            _scope.type = 'NonPositiveInteger';

            _formValue.$setViewValue('0');

            expect(_formValue.$valid).toBe(true);
        });

        it('should be invalid for incorrect NonPositiveInteger', function() {
            _scope.type = 'NonPositiveInteger';

            _formValue.$setViewValue('1');

            expect(_formValue.$valid).toBe(false);
        });

        it('should be valid for correct NegativeInteger', function() {
            _scope.type = 'NegativeInteger';

            _formValue.$setViewValue('-1');

            expect(_formValue.$valid).toBe(true);
        });

        it('should be invalid for incorrect NegativeInteger', function() {
            _scope.type = 'NegativeInteger';

            _formValue.$setViewValue('0');

            expect(_formValue.$valid).toBe(false);
        });

        it('should be valid for correct PositiveInteger', function() {
            _scope.type = 'PositiveInteger';

            _formValue.$setViewValue('1');

            expect(_formValue.$valid).toBe(true);
        });

        it('should be invalid for incorrect PositiveInteger', function() {
            _scope.type = 'PositiveInteger';

            _formValue.$setViewValue('0');

            expect(_formValue.$valid).toBe(false);
        });

        it('should be valid for correct NonNegativeInteger', function() {
            _scope.type = 'NonNegativeInteger';

            _formValue.$setViewValue('0');

            expect(_formValue.$valid).toBe(true);
        });

        it('should be invalid for incorrect NonNegativeInteger', function() {
            _scope.type = 'NonNegativeInteger';

            _formValue.$setViewValue('-1');

            expect(_formValue.$valid).toBe(false);
        });
    });

    describe('saving to model', function() {
        it('should save valid view value to model', function() {
            _formValue.$setViewValue('1');

            expect(_formValue.$modelValue).toBe('1');
        });

        it('should not save invalid view value to model', function() {
            _scope.type = 'Integer';

            _formValue.$setViewValue('1.1');

            expect(_formValue.$modelValue).not.toBe('1.1');
        });
    });
});