describe('inprotech.configuration.general.standinginstructions.AssignedArray', function() {
    'use strict';

    var AssignedArray, ArrayExt, currentArray;

    var getRecord = function(array, id) {
        return _.find(array.items, function(a) {
            return a.obj.id === id;
        });
    };

    beforeEach(module('inprotech.configuration.general.standinginstructions'));

    beforeEach(inject(function(_AssignedArray_, _ArrayExt_) {
        AssignedArray = _AssignedArray_;
        ArrayExt = _ArrayExt_;

        var current = [{
            id: 1,
            selected: true
        }, {
            id: 2,
            selected: false
        }];

        currentArray = new AssignedArray(current);
    }));

    describe('function', function() {
        it('mergeByProperty should extend object with passed array objects', function() {
            var passed = [{
                id: 1,
                additionalField: 'xyz'
            }, {
                id: 5,
                additionalField: 'abc'
            }];
            var passedArray = new ArrayExt(passed);

            currentArray.mergeByProperty(passedArray, 'id');

            expect(currentArray.items.length).toBe(3);
            expect(getRecord(passedArray, 1).obj.additionalField).toBe('xyz');
            expect(getRecord(passedArray, 5).obj.additionalField).toBe('abc');
        });

        it('revert should set the items back to original items', function() {
            getRecord(currentArray, 1).obj.selected = false;
            getRecord(currentArray, 1).obj.description = 'ABCD';

            currentArray.revert();

            expect(getRecord(currentArray, 1).obj.selected).toBe(true);
            expect(getRecord(currentArray, 1).obj.description).not.toBeDefined();
        });

        it('isDirty should return true, if it has status apart from none', function() {
            getRecord(currentArray, 1).status = 'a';
            var result = currentArray.isDirty();

            expect(result).toBe(true);
        });

        it('isDirty should return false, if it has status apart from none', function() {
            getRecord(currentArray, 1).status = 'none';
            var result = currentArray.isDirty();

            expect(result).toBe(false);
        });

        it('sanitize set the items to passed valid ids', function() {
            var validIds = [1];

            currentArray.sanitize(validIds);

            expect(currentArray.items.length).toBe(1);
            expect(_.first(currentArray.items).obj.id).toBe(1);
        });

        it('setValue should set the value of item', function() {
            spyOn(getRecord(currentArray, 1), 'changeStatus');

            currentArray.setValue(1, false, false);

            expect(getRecord(currentArray, 1).obj.selected).toBe(false);
            expect(getRecord(currentArray, 1).changeStatus).toHaveBeenCalledWith(false);
        });

        it('isUpdated should return true if status not equal to none', function() {
            getRecord(currentArray, 1).status = 'a';
            expect(currentArray.isUpdated(1)).toBe(true);
        });

        it('isUpdated should return false if status equal to none', function() {
            getRecord(currentArray, 1).status = 'none';
            expect(currentArray.isUpdated(1)).toBe(false);
        });


        it('isSaved should return true if saved', function() {
            getRecord(currentArray, 1).isSaved = true;
            expect(currentArray.isSaved(1)).toBe(true);
        });


        it('isSaved should return false if not saved', function() {
            getRecord(currentArray, 1).isSaved = false;
            expect(currentArray.isSaved(1)).toBe(false);
        });
    });
});
