describe('inprotech.api.extensions.dirtycheck', function() {
    'use strict';

    beforeEach(module('inprotech.api.extensions'));
    describe('configuration', function() {
        it('should have correct function', inject(function(restmod) {
            var dummy = restmod.model('api/dummy').mix('dirtyCheck');
            expect(dummy.$new().$isDirty).toBeDefined();
            expect(dummy.$collection().$isDirty).toBeDefined();
            expect(dummy.$collection().$filterOutUnchanged).toBeDefined();

            expect(dummy.$new().$dirty).toBeDefined();
            expect(dummy.$new().$isNewOrDeleted).toBeDefined();
            expect(dummy.$new().$isNew).toBeDefined();
            expect(dummy.$new().$isFakeDelete).toBeDefined();
        }));
    });

    describe('record methods -', function() {
        var dummyApi, dummyRecord;
        beforeEach(inject(function(restmod) {
            dummyApi = restmod.model('api/dummy').mix('dirtyCheck');
            dummyRecord = dummyApi.$new().$unwrap({
                id: 1,
                someField: 'ZZZ',
                state: 'none'
            });
        }));
        it('isDirty should return true if $dirty returns 1 or more fields', function() {
            dummyRecord.someField = 'A';
            expect(dummyRecord.$isDirty()).toBeTruthy();
        });

        it('$dirty should return dirty fields except state field', function() {
            dummyRecord.someField = 'A';
            var result = dummyRecord.$dirty();
            expect(result).toEqual(['someField']);
        });
        it('$dirty should return false if field is not changed', function() {
            expect(dummyRecord.$dirty('someField')).toBeFalsy();
        });
        it('$dirty should return true if field is changed', function() {
            dummyRecord.someField = 'A';
            expect(dummyRecord.$dirty('someField')).toBeTruthy();
        });
        it('isNewOrDeleted should return true if state is added', function() {
            dummyRecord.state = 'added';
            expect(dummyRecord.$isNewOrDeleted()).toBeTruthy();
        });
        it('isNewOrDeleted should return true if state is deleted', function() {
            dummyRecord.state = 'deleted';
            expect(dummyRecord.$isNewOrDeleted()).toBeTruthy();
        });
        it('isNewOrDeleted should return false if state is none', function() {
            dummyRecord.state = 'none';
            expect(dummyRecord.$isNewOrDeleted()).toBeFalsy();
        });
        it('isNewOrDeleted should return false if state is updated', function() {
            dummyRecord.state = 'updated';
            expect(dummyRecord.$isNewOrDeleted()).toBeFalsy();
        });
        it('isNew should return true if id is not present', function() {
            dummyRecord.id = null;
            expect(dummyRecord.$isNew()).toBeTruthy();
        });
        it('isNew should return false if id is not present', function() {
            expect(dummyRecord.$isNew()).toBeFalsy();
        });
        it('isFakeDelete should return true if newly added record is deleted', function() {
            dummyRecord.id = null;
            dummyRecord.state = 'deleted';
            expect(dummyRecord.$isFakeDelete()).toBeTruthy();
        });
        it('isFakeDelete should return false if existing record is deleted', function() {
            dummyRecord.state = 'deleted';
            expect(dummyRecord.$isFakeDelete()).toBeFalsy();
        });
        it('isFakeDelete should return false for newly added record', function() {
            dummyRecord.id = null;
            expect(dummyRecord.$isFakeDelete()).toBeFalsy();
        });
    });
    describe('collection methods -', function() {
        var dummyApi, dummyColl;
        beforeEach(inject(function(restmod) {
            dummyApi = restmod.model('api/dummy').mix('dirtyCheck');
            dummyColl = dummyApi.$collection().$unwrap([{
                id: 1,
                someField: 'ZZZ',
                state: 'none'
            }, {
                id: 2,
                someField: 'YYY',
                state: 'none'
            }, {
                id: 3,
                someField: 'XXX',
                state: 'none'
            }, {
                id: 4,
                someField: 'WWW',
                state: 'none'
            }]);
        }));
        it('isDirty should return false if nothing is changed', function() {
            expect(dummyColl.$isDirty()).toBeFalsy();
        });
        it('isDirty should return true if any record is dirty', function() {
            dummyColl[0].someField = 'A';
            expect(dummyColl.$isDirty()).toBeTruthy();
        });
        it('isDirty should return true if any record is in added state', function() {
            dummyColl[0].state = 'added';
            expect(dummyColl.$isDirty()).toBeTruthy();
        });
        it('isDirty should return true if any record is in deleted state', function() {
            dummyColl[0].state = 'deleted';
            expect(dummyColl.$isDirty()).toBeTruthy();
        });
        it('filterOutUnchanged should return all records without state as none', function() {
            dummyColl[0].state = 'added';
            dummyColl[3].state = 'deleted';
            var result = dummyColl.$filterOutUnchanged();
            expect(result.length).toEqual(2);
            expect(result[0].state).toEqual('added');
            expect(result[0].someField).toEqual('ZZZ');
            expect(result[1].state).toEqual('deleted');
            expect(result[1].someField).toEqual('WWW');
        });
        it('filterOutUnchanged should return without fake deleted records', function() {
            dummyColl[3].state = 'deleted';
            dummyColl[3].id = null;
            dummyColl[0].state = 'updated';
            dummyColl[1].state = 'updated';
            dummyColl[2].state = 'updated';
            var result = dummyColl.$filterOutUnchanged();
            expect(result.length).toEqual(3);
        });
    });
});
