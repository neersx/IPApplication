describe('inprotech.api.extensions.stateFlag', function() {
    'use strict';

    beforeEach(module('inprotech.api.extensions'));
    describe('configuration', function() {
        it('should have correct function', inject(function(restmod) {
            var dummy = restmod.model('api/dummy').mix('stateFlag');
            expect(dummy.$new().$revertDelete).toBeDefined();
            expect(dummy.$new().$dirty).toBeDefined();
            expect(dummy.$new().$markDeleted).toBeDefined();
            expect(dummy.$new().$build).toBeDefined();
            expect(dummy.$collection().$markDeleted).toBeDefined();
            expect(dummy.$collection().$build).toBeDefined();
        }));
    });
    describe('record methods -', function() {
        var dummyApi, dummyRecord;
        beforeEach(inject(function(restmod) {
            dummyApi = restmod.model('api/dummy').mix('stateFlag');
            dummyRecord = dummyApi.$new().$unwrap({
                id: 1,
                someField: 'ZZZ'
            });
        }));

        it('should set initial state to none', function() {
            expect(dummyRecord.state).toEqual('none');
        });

        it('markDeleted should set the state as deleted', function() {
            dummyRecord.$markDeleted();
            expect(dummyRecord.state).toEqual('deleted');
        });

        it('revert delete should set the state to init if nothing is changed', function() {
            dummyRecord.$markDeleted();
            dummyRecord.$revertDelete();
            expect(dummyRecord.state).toEqual('none');
        });
        it('revert delete should set the state to added if the record is new', function() {
            var newRecord = dummyApi.$new();
            newRecord.$markDeleted();
            newRecord.$revertDelete();
            expect(newRecord.state).toEqual('added');
        });
        it('revert delete should set the state to updated if the record is edited', function() {
            dummyRecord.someField = 'AAA';
            dummyRecord.$markDeleted();
            dummyRecord.$revertDelete();
            expect(dummyRecord.state).toEqual('updated');
        });

    });
    describe('collection methods -', function() {
        var dummyApi, dummyColl;
        beforeEach(inject(function(restmod) {
            dummyApi = restmod.model('api/dummy').mix('stateFlag');
            dummyColl = dummyApi.$collection().$unwrap([{
                id: 1,
                someField: 'ZZZ'
            }, {
                id: 2,
                someField: 'YYY'
            }, {
                id: 3,
                someField: 'YYY'
            }, {
                id: 4,
                someField: 'YYY'
            }]);
        }));
        it('markDeleted should set the state as deleted for all records marked', function() {
            dummyColl[0].marked = true;
            dummyColl[3].marked = true;
            dummyColl.$markDeleted();
            expect(dummyColl[0].state).toEqual('deleted');
            expect(dummyColl[3].state).toEqual('deleted');
            expect(dummyColl[1].state).toEqual('none');
            expect(dummyColl[2].state).toEqual('none');
        });
    });
});