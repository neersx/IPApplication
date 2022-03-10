describe('Service inprotech.components.bulkactions.menuHelper', function() {
    'use strict';

    var dataSource, menuSel, service;

    beforeEach(function() {
        module('inprotech.components')
        module('inprotech.components.bulkactions');
    });

    describe('bulk menu operations full set mode', function() {
        beforeEach(inject(function(BulkMenuOperations, menuSelection) {
            service = new BulkMenuOperations('context');
            menuSel = menuSelection;

            dataSource = [{ id: 1, selected: false }, { id: 2, selected: false }, { id: 3, selected: false }];
        }));

        it('should select all data and update menu selection', function() {
            spyOn(menuSel, 'updateData');

            service.selectAll(dataSource, true);

            var result = _.every(dataSource, function(data) {
                return data.selected == true;
            });

            expect(result).toBe(true);
            expect(menuSel.updateData).toHaveBeenCalled();
        });

        it('should clear all data and update menu selection', function() {
            _.each(dataSource, function(data) {
                data.selected = true;
            });

            service.clearAll(dataSource);

            var result = _.every(dataSource, function(data) {
                return data.selected == false;
            });

            expect(result).toBe(true);
        });

        it('should retrieve selected records from dataSource', function() {
            dataSource[0].selected = true;

            var result = service.selectedRecords(dataSource);

            expect(result[0].id).toBe(1);
        });

        it('should evaluate if any record is selected', function() {
            dataSource[0].selected = true;

            var result = service.anySelected(dataSource);
            expect(result).toBe(true);
        });
    });

    describe('bulk menu operations multipage mode', function() {
        beforeEach(inject(function(BulkMenuOperations, menuSelection) {
            service = new BulkMenuOperations('context');
            menuSel = menuSelection;

            spyOn(menuSel, 'updatePaginationInfo');

            dataSource = [{ id: 1, selected: false }, { id: 2, selected: false }, { id: 3, selected: false }];
            service.initialiseMenuForPaging(20);
        }));

        it('should initialise paging with multi-page mode', function() {
            expect(service.isMultipagePageMode).toEqual(true);
            expect(menuSel.updatePaginationInfo).toHaveBeenCalledWith('context', true, 20);
        });

        it('should select all page data and update menu selection', function() {
            spyOn(menuSel, 'updateData');

            service.selectPage(dataSource, true);

            var result = _.every(dataSource, function(data) {
                return data.selected == true;
            });
            var selected = service.selectedRecords();

            expect(result).toBe(true);
            expect(menuSel.updateData).toHaveBeenCalled();
            expect(selected.length).toBe(dataSource.length);
        });

        it('should clear all data and update menu selection', function() {
            _.each(dataSource, function(data) {
                data.selected = true;
            });

            service.clearAll(dataSource);

            var result = _.every(dataSource, function(data) {
                return data.selected == false;
            });

            var selected = service.anySelected();

            expect(result).toBe(true);
            expect(selected).toBe(false);
        });

        it('should retrieve selected records from selected list', function() {
            dataSource[0].selected = true;
            service.singleSelectionChange(dataSource, dataSource[0]);

            var result = service.selectedRecords();
            expect(result[0].id).toBe(1);
        });
        it('should retrieve selected records from selected list correctly with one of records having id assigned as 0', function() {
            dataSource.push({ id: 0, selected: false });

            //select first record
            dataSource[0].selected = true;
            service.singleSelectionChange(dataSource, dataSource[0]);

            //select record with id = 0
            dataSource[3].selected = true;
            service.singleSelectionChange(dataSource, dataSource[3]);

            //deselect record with id = 0
            dataSource[3].selected = false;
            service.singleSelectionChange(dataSource, dataSource[3]);

            var result = service.selectedRecords();
            expect(result.length).toBe(1);
            expect(result[0].id).toBe(1);
        });

        it('should evaluate if any record is selected', function() {

            dataSource[0].selected = true;
            service.singleSelectionChange(dataSource, dataSource[0]);

            var result = service.anySelected(dataSource);
            expect(result).toBe(true);
        });

        it('should evaluate if full page is selected', function() {
            dataSource[0].selected = true;
            dataSource[1].selected = true;
            dataSource[2].selected = true;
            service.singleSelectionChange(dataSource, dataSource[0]);
            spyOn(menuSel, 'updateData');
            service.singleSelectionChange(dataSource, dataSource[1]);
            expect(menuSel.updateData).toHaveBeenCalledWith('context', null, 3, 2, false);
            service.singleSelectionChange(dataSource, dataSource[2]);
            expect(menuSel.updateData).toHaveBeenCalledWith('context', null, 3, 3, true);

            service.selectionChange(dataSource);
            expect(menuSel.updateData).toHaveBeenCalledWith('context', null, 3, 3, true);
        });

        it('should update on pre-selected records from selected list', function() {
            dataSource[0].selected = true;
            dataSource[1].selected = true;
            service.singleSelectionChange(dataSource, dataSource[0]);
            service.singleSelectionChange(dataSource, dataSource[1]);
            service.selectionChange(dataSource, [1]);
            var result = service.selectedRecords(dataSource);

            expect(result.length).toBe(1);
            expect(result[0].inUse).toBe(true)
        });
    });
});