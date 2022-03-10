describe('inprotech.components.grid.kendoGridService', function() {
    'use strict';

    var service;
    beforeEach(function() {
        module('inprotech.components.grid');
        inject(function(kendoGridService) {
            service = kendoGridService;
        });
    });

    describe('isGridDirty', function() {
        it('returns true if and records added, edited or deleted', function() {
            var gridOptions = {
                dataSource: {
                    data: _.constant([])
                }
            };
            expect(service.isGridDirty(gridOptions)).toBe(false);

            gridOptions.dataSource.data = _.constant([{
                added: true
            }]);
            expect(service.isGridDirty(gridOptions)).toBe(true);

            gridOptions.dataSource.data = _.constant([{
                isEdited: true
            }]);
            expect(service.isGridDirty(gridOptions)).toBe(true);

            gridOptions.dataSource.data = _.constant([{
                deleted: true
            }]);
            expect(service.isGridDirty(gridOptions)).toBe(true);
        });
    });

    function initGridOptions(existingData) {
        return {
            dataSource: {
                data: jasmine.createSpy().and.returnValue(existingData),
                add: jasmine.createSpy(),
                remove: jasmine.createSpy()
            }
        };
    }

    describe('sync', function() {
        it('should mark existing items as deleted', function() {
            var existingData = {key: 1, value: 'abc'};
            var gridOptions = initGridOptions([existingData]);

            service.sync(gridOptions, [], null);

            expect(existingData.deleted).toBe(true);

        });

        it('should remove newly added items that were unselected', function() {
            var existingData = {key: 1, value: 'abc', isAdded: true};
            var gridOptions = initGridOptions([existingData]);

            service.sync(gridOptions, [], null);

            expect(gridOptions.dataSource.remove).toHaveBeenCalledWith(existingData);
        });

        it('does not add a duplicate', function() {
            var gridOptions = initGridOptions([{
                key: -1
            }]);

            service.sync(gridOptions, [{
                key: -1
            }]);

            expect(gridOptions.dataSource.add).not.toHaveBeenCalled();
        });

        it('undeletes re-selected items', function() {
            var existingData = [{
                key: -1,
                deleted: true
            }];
            var gridOptions = initGridOptions(existingData);

            service.sync(gridOptions, [{
                key: -1
            }]);

            expect(existingData[0].deleted).toBe(false);
            expect(gridOptions.dataSource.add).not.toHaveBeenCalled();
        });

        it('adds new items', function() {
            var gridOptions = initGridOptions([]);

            service.sync(gridOptions, [{
                key: -1,
                value: 'abc'
            }]);

            expect(gridOptions.dataSource.add).toHaveBeenCalledWith({
                isAdded: true,
                deleted: false,
                key: -1,
                value: 'abc'
            });
        });
    });

    describe('activeData', function() {
        it('returns not deleted rows', function() {
            var item1 = { 
                key: 2,
                isAdded: true
            };
            var item2 = {
                key: 3,
                isEdited: true
            };

            service.data = jasmine.createSpy().and.returnValue([{
                key: 1,
                deleted: true
            }, item1, item2]);

            var result = service.activeData();
            expect(result.length).toBe(2);
            expect(result[0]).toBe(item1);
            expect(result[1]).toBe(item2);
        });
    });

    describe('hasActiveItems', function() {
        it('returns true if there are non-deleted items', function() {
            var gridOptions = initGridOptions([{
                key: -1,
                deleted: true
            }, {
                key: -2,
                deleted: false
            }]);

            expect(service.hasActiveItems(gridOptions)).toBe(true);
        });

        it('returns false if there are no active items', function() {
            var gridOptions = initGridOptions([{
                key: -1,
                deleted: true
            }]);

            expect(service.hasActiveItems(gridOptions)).toBe(false);
        });
    });
});
