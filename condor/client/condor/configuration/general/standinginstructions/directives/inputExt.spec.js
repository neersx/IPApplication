describe('inprotech.configuration.general.standinginstructions.InputExt', function() {
    'use strict';

    /* eslint no-unused-vars:0*/
    beforeEach(function() {
        module('inprotech.configuration.general.standinginstructions');
    });

    var scope, form;

    var inputCtrl = '<form name="form">' +
        '<input input-ext ng-model="desc" name="elem" on-value-change="callback(isReverted)"  required validator-funcs="{check : checkValid}" ng-model-options="{ allowInvalid: true }"/>' +
        '</form>';

    var setTextValue = function(text) {
        form.elem.$setViewValue(text);
        scope.$digest();
    };

    beforeEach(inject(function($rootScope, $compile) {
        scope = $rootScope.$new();
        scope.desc = 'oldValue';
        scope.callback = function(isReverted) {};
        scope.checkValid = function(m, v) {
            return false;
        };

        $compile(inputCtrl)(scope);
        scope.$digest();
        form = scope.form;
    }));

    describe('text reset functionality', function() {
        it('should call onValueChange callback', function() {
            spyOn(scope, 'callback').and.callThrough();

            setTextValue('newValue');

            expect(scope.desc).toBe('newValue');
            expect(form.elem.$dirty).toBe(true);
            expect(scope.callback).toHaveBeenCalledWith(false);
        });

        it('should reset $dirty, when value is reverted', function() {
            setTextValue('newValue');
            expect(form.elem.$dirty).toBe(true);

            spyOn(scope, 'callback').and.callThrough();

            setTextValue('oldValue');
            expect(form.elem.$dirty).toBe(false);
            expect(scope.desc).toBe('oldValue');
            expect(scope.callback).toHaveBeenCalledWith(true);
        });

        it('should reset to original value', function() {
            setTextValue('newValue');
            expect(form.elem.$dirty).toBe(true);

            form.elem.reset();
            expect(scope.desc).toBe('oldValue');
            expect(form.elem.$dirty).toBe(false);
        });

        it('should set the view value as new value', function() {
            setTextValue('newValue');

            form.elem.setNewValue();
            form.elem.reset();

            expect(scope.desc).toBe('newValue');
            expect(form.elem.$dirty).toBe(false);
        });
    });

    describe('$dirty manipulation functionality', function() {
        it('should not set $dirty when setIfDirty is called without any changes', function() {
            form.elem.$setDirty(true);
            expect(form.elem.$dirty).toBe(true);

            form.elem.setIfDirty();
            expect(form.elem.$dirty).toBe(false);
        });

        it('should set $dirty when setIfDirty is called with changes', function() {
            setTextValue('newValue');
            form.elem.$setPristine(true);
            expect(form.elem.$dirty).toBe(false);

            form.elem.setIfDirty();
            expect(form.elem.$dirty).toBe(true);
        });

        it('should set $dirty, when object is marked deleted', function() {
            spyOn(form.elem, 'resetErrors').and.callThrough();
            spyOn(form.elem, '$setDirty').and.callThrough();

            form.elem.markDeleted();

            expect(form.elem.resetErrors).toHaveBeenCalled();
            expect(form.elem.$setDirty).toHaveBeenCalled();
        });

        it('should reset $dirty, when object is marked undeleted', function() {
            spyOn(form.elem, '$validate').and.callThrough();
            spyOn(form.elem, 'setIfDirty').and.callThrough();

            form.elem.markDeleted(true);

            expect(form.elem.$validate).toHaveBeenCalled();
            expect(form.elem.setIfDirty).toHaveBeenCalled();
        });
    });

    describe('validations related functionality', function() {
        it('reset errors', function() {
            setTextValue('');
            expect(form.elem.$error.required).toBe(true);

            form.elem.resetErrors();
            expect(form.elem.$error.required).not.toBeDefined();
        });

        it('should call assigned validators', function() {
            spyOn(form.elem.$validators, 'check').and.callThrough();

            setTextValue('a');
            expect(form.elem.$error.check).toBe(true);

            expect(form.elem.$validators.check).toHaveBeenCalled();
        });
    });
});
