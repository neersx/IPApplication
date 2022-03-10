describe('inprotech.configuration.general.standinginstructions.FormExt', function() {
    'use strict';

    /* eslint no-unused-vars:0*/
    beforeEach(function() {
        module('inprotech.configuration.general.standinginstructions');
    });

    var scope, form;

    var inputCtrl = '<form form-ext name="form">' +
        '<input input-ext name="elem1" ng-model="desc1" ng-model-options="{ allowInvalid: true }"/>' +
        '<input input-ext name="elem2" ng-model="desc1" ng-model-options="{ allowInvalid: true }"/>' +
        '</form>';


    beforeEach(inject(function($rootScope, $compile) {
        scope = $rootScope.$new();
        scope.desc1 = 'oldval1';
        scope.desc2 = 'oldval2';

        $compile(inputCtrl)(scope);

        scope.$digest();
        form = scope.form;
    }));

    describe('functionality', function() {
        it('should call reset of all controls', function() {
            spyOn(form.elem1, 'reset').and.callThrough();
            spyOn(form.elem2, 'reset').and.callThrough();
            spyOn(form, '$setPristine').and.callThrough();
            spyOn(form, '$setUntouched').and.callThrough();

            form.reset();

            expect(form.elem1.reset).toHaveBeenCalled();
            expect(form.elem2.reset).toHaveBeenCalled();
            expect(form.$setPristine).toHaveBeenCalled();
            expect(form.$setUntouched).toHaveBeenCalled();
        });

        it('should call setNewValue of all controls', function() {
            spyOn(form.elem1, 'setNewValue').and.callThrough();
            spyOn(form.elem2, 'setNewValue').and.callThrough();
            spyOn(form, '$setPristine').and.callThrough();
            spyOn(form, '$setUntouched').and.callThrough();

            form.setSavedValues();

            expect(form.elem1.setNewValue).toHaveBeenCalled();
            expect(form.elem2.setNewValue).toHaveBeenCalled();
            expect(form.$setPristine).toHaveBeenCalled();
            expect(form.$setUntouched).toHaveBeenCalled();
        });

        it('isDirty should return true, if any control is dirty', function() {
            form.elem1.$dirty = true;
            form.elem2.$dirty = false;

            var result = form.isDirty();

            expect(result).toBe(true);
        });

        it('isDirty should return false, if any control is dirty', function() {
            form.elem1.$dirty = false;
            form.elem2.$dirty = false;
            var result = form.isDirty();

            expect(result).toBe(false);
        });

        it('savable should return true, isDirty returns true', function() {
            spyOn(form, 'isDirty').and.returnValue(true);
            form.$valid = true;
            var result = form.savable();

            expect(result).toBe(true);
        });

        it('savable should return false, if form invalid', function() {
            spyOn(form, 'isDirty').and.returnValue(true);
            form.$valid = false;
            var result = form.savable();

            expect(result).toBe(false);
        });
    });
});
