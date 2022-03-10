describe('inprotech.configuration.general.standinginstructions.ArrayExt', function() {
    'use strict';

    var ArrayExt, currentArray;

    var getRecord = function(array, id) {
        return _.find(array.items, function(a) {
            return a.obj.id === id;
        });
    };

    beforeEach(module('inprotech.configuration.general.standinginstructions'));

    beforeEach(inject(function(_ArrayExt_) {
        ArrayExt = _ArrayExt_;

        var current = [{
            id: 1,
            description: 'abcd'
        }, {
            id: 2,
            description: 'efgh'
        }];

        currentArray = new ArrayExt(current);
    }));

    describe('array related functions', function() {
        var passedArray;
        beforeEach(function() {
            var passed = [{
                id: 1
            }];
            passedArray = new ArrayExt(passed);
        });

        it('function length, should return number of items', function() {
            expect(currentArray.length()).toBe(2);
        });

        it('function length, should return 0, if not items in array', function() {
            var newArray = new ArrayExt();
            expect(newArray.length()).toBe(0);
        });

        it('function clear, should return clear items in array', function() {
            currentArray.clear();
            expect(_.first(currentArray.items)).not.toBeDefined();
        });

        it('function addNew, should add object to an array', function() {
            var object = {
                id: 3,
                description: 'xyz'
            };

            currentArray.addNew(object);
            expect(currentArray.items.length).toBe(3);
            expect(_.isEqual(_.last(currentArray.items).obj, object)).toBe(true);
            expect(_.last(currentArray.items).newlyAdded).toBe(true);
        });

        it('function anyAdditions, checks if any object with status as added', function() {
            getRecord(currentArray, 1).status = 'added';
            expect(currentArray.anyAdditions()).toBe(true);
        });

        it('function anyAdditions, checks if any object with status as added and not marked as deleted is present', function() {
            getRecord(currentArray, 1).status = 'added';
            getRecord(currentArray, 1).isDeleted = true;

            expect(currentArray.anyAdditions()).toBe(false);
        });

        it('function setSavedState, marks items as saved for recieved array', function() {
            _.first(passedArray.items).isSaved = true;
            currentArray.setSavedState(passedArray, 'id');

            expect(getRecord(currentArray, 1).isSaved).toBe(true);
        });

        it('function setError, marks items as saved for recieved array', function() {
            var errorArray = [{
                id: 1,
                message: 'error'
            }];

            var firstItem = getRecord(currentArray, 1);
            spyOn(firstItem, 'setError').and.callThrough();
            currentArray.setError(errorArray);

            expect(firstItem.setError).toHaveBeenCalled();
        });
    });

    describe('status related functions', function() {
        it('function revertAll, should reveret all changes', function() {
            var firstItem = getRecord(currentArray, 1);
            var secondItem = getRecord(currentArray, 2);

            spyOn(firstItem, 'changeStatus').and.callThrough();
            spyOn(secondItem, 'changeStatus').and.callThrough();
            spyOn(currentArray, 'removeItems').and.callThrough();
            spyOn(currentArray, 'undoDelete').and.callThrough();

            currentArray.revertAll();

            expect(firstItem.changeStatus).toHaveBeenCalledWith(true);
            expect(secondItem.changeStatus).toHaveBeenCalledWith(true);
            expect(currentArray.removeItems).toHaveBeenCalledWith('added');
            expect(currentArray.undoDelete).toHaveBeenCalled();

        });

        it('function removeItems, should remove specified items', function() {
            getRecord(currentArray, 2).status = 'a';
            currentArray.removeItems('a');

            expect(currentArray.items.length).toBe(1);
            expect(getRecord(currentArray, 1)).toBeDefined();
        });

        it('function undoDelete, should set isDeleted flag to false for all items', function() {
            getRecord(currentArray, 1).isDeleted = true;
            currentArray.undoDelete();

            expect(getRecord(currentArray, 1).isDeleted).toBe(false);
            expect(getRecord(currentArray, 2).isDeleted).toBe(false);
        });

        it('function getChanges, should return separate arrays with changes', function() {
            currentArray.addNew({
                id: 5
            });
            currentArray.addNew({
                id: 6
            });

            getRecord(currentArray, 1).isDeleted = true;
            getRecord(currentArray, 2).status = 'updated';
            getRecord(currentArray, 5).status = 'none';
            getRecord(currentArray, 6).status = 'added';

            var updates = currentArray.getChanges();
            expect(updates.deleted.length).toBe(1);
            expect(_.first(updates.deleted).id).toBe(1);

            expect(updates.updated.length).toBe(1);
            expect(_.first(updates.updated).id).toBe(2);

            expect(updates.added.length).toBe(1);
            expect(_.first(updates.added).id).toBe(6);
        });
    });

    describe('internal object related functions', function() {
        it('function pushOrGet, should get item if found', function() {
            var i = currentArray.pushOrGet('id', 1);

            expect(i).toBeDefined();
            expect(currentArray.items.length).toBe(2);
        });

        it('function pushOrGet, should push item if not found', function() {
            var i = currentArray.pushOrGet('id', 5);

            expect(i).toBeDefined();
            expect(currentArray.items.length).toBe(3);
        });

        it('function get, should get item with specified property', function() {
            var i = currentArray.get('description', 'abcd');

            expect(_.isEqual(i, getRecord(currentArray, 1))).toBe(true);
        });

        it('function checkUniqueness, should return true if value is unique', function() {
            var result = currentArray.checkUniqueness('description', 'abcd');
            expect(result).toBe(true);
        });

        it('function checkUniqueness, should return true if value is unique', function() {
            getRecord(currentArray, 2).obj.description = 'abcd';
            var result = currentArray.checkUniqueness('description', 'abcd');
            expect(result).toBe(false);
        });

        it('function checkUniqueness, should exclude deleted items from unique check', function() {
            getRecord(currentArray, 2).obj.description = 'abcd';
            getRecord(currentArray, 2).isDeleted = true;
            var result = currentArray.checkUniqueness('description', 'abcd');
            expect(result).toBe(true);
        });

        it('function getValidIds, should exclude deleted items and get ids', function() {
            getRecord(currentArray, 1).isDeleted = true;
            var result = currentArray.getValidIds();
            expect(result.length).toBe(1);
            expect(_.first(result)).toBe(2);
        });
    });
});
