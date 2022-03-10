describe('inprotech.components.form.ipEmail', function() {
    'use strict';
    var _compile, _element, _scope, _formValue;

    beforeEach(module('inprotech.components.form'));

    beforeEach(inject(function($rootScope, $compile) {
        _compile = $compile;

        _scope = $rootScope.$new();

        _scope.current = {
            value: 'aabbcc'
        };

        _element = '<input class="form-control" name="value" ip-email ng-model="current.value" type="text" required>';

        var form = '<form name="nodeForm">' + _element + '</form>';

        _compile(form)(_scope);
        _scope.$digest();

        _formValue = _scope.nodeForm.value;

    }));

    describe('Email type validation', function() {
        it('should be valid for correct email', function() {
            _formValue.$setViewValue('aa@bb.com');
            expect(_formValue.$valid).toBe(true);
        });

        it('should be valid for correct email with _', function() {
            _formValue.$setViewValue('a.a_aBBB@ccc');
            expect(_formValue.$valid).toBe(true);
        });

        it('should be valid AAA_BBB@cc.com', function() {
            _formValue.$setViewValue('AAA_BBB@cc.com');
            expect(_formValue.$valid).toBe(true);
        });
    });
});