describe('inprotech.configuration.general.standinginstructions.ObjectExt', function() {
    'use strict';

    var ObjectExt, obj, o;

    beforeEach(module('inprotech.configuration.general.standinginstructions'));

    beforeEach(inject(function(_ObjectExt_) {
        ObjectExt = _ObjectExt_;

        o = {
            id: 1
        };
        obj = new ObjectExt(o);
    }));

    describe('status related functionality', function() {
        it('function changeStatus, should change status to updated on change', function() {
            obj.changeStatus(false);

            expect(obj.status).toBe('updated');
        });

        it('function changeStatus, should reset status to none if change reverted', function() {
            obj.status = 'updated';
            obj.changeStatus(true);

            expect(obj.status).toBe('none');
        });

        it('function changeStatus, should not change status if status is added', function() {
            obj.status = 'added';

            obj.changeStatus(true);
            expect(obj.status).toBe('added');

            obj.changeStatus(false);
            expect(obj.status).toBe('added');
        });

        it('function delete, should toggle isDeleted flag', function() {
            obj.delete();
            expect(obj.isDeleted).toBe(true);

            obj.delete();
            expect(obj.isDeleted).toBe(false);
        });

        it('function setNew, should mark the record as new', function() {
            obj.setNew();

            expect(obj.status).toBe('added');
            expect(obj.newlyAdded).toBe(true);
        });

        it('function resetNewlyAdded, should reset newlyAdded flag', function() {
            obj.newlyAdded = true;
            obj.resetNewlyAdded();

            expect(obj.newlyAdded).toBe(false);
        });

        it('function setError, should set server error message', function() {
            obj.setError('serverError');

            expect(obj.serverError).toBe(true);
            expect(obj.serverErrorMsg).toBe('serverError');
        });
    });

    describe('getErrorText function', function() {
        it('should return blank if no errors', function() {
            expect(obj.getErrorText()).toBe('');
        });

        it('should return correct error message for required', function() {
            var error = {
                required: true
            };
            expect(obj.getErrorText(error)).toBe('field.errors.required');
        });

        it('should return correct error message for maxlength', function() {
            var error = {
                maxlength: true
            };
            expect(obj.getErrorText(error)).toBe('field.errors.maxlength');
        });

        it('should return correct error message for notunique', function() {
            var error = {
                isUnique: true
            };
            expect(obj.getErrorText(error)).toBe('field.errors.notunique');
        });

        it('should return server error message if presetnt', function() {
            var error = {
                isUnique: true
            };

            obj.serverError = true;
            obj.serverErrorMsg = 'serverError';
            expect(obj.getErrorText(error)).toBe('serverError');
        });
    });

    describe('getObj function', function() {
        it('should return underlying object', function() {
            var object = obj.getObj();

            expect(_.isEqual(o, object)).toBe(true);
        });
    });
});
