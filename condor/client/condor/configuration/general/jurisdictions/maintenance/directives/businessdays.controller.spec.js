describe('inprotech.configuration.general.jurisdictions.BusinessDaysController', function() {
    'use strict';

    var controller, kendoGridBuilder, service, modalService, notificationService;

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.jurisdictions', 'inprotech.mocks.components.grid', 'inprotech.mocks']);

            service = $injector.get('JurisdictionMaintenanceServiceMock');
            $provide.value('jurisdictionBusinessDaysServiceMock', service);
            modalService = $injector.get('modalServiceMock');
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            notificationService = $injector.get('notificationServiceMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);
            $provide.value('modalService', modalService);
            test.mock('dateService');
            $provide.value('notificationService', notificationService)
        });
    });

    beforeEach(inject(function($controller) {
        controller = function() {
            var c = $controller('BusinessDaysController', {
                $scope: {
                    parentId: 'AU',
                    workDayFlag: 31
                }
            }, {
                topic: { canUpdate: true }
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialise', function() {
        it('should initialise the page,and display the correct columns', function() {
            var c = controller();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
            expect(_.pluck(c.gridOptions.columns, 'field')).toEqual([undefined, 'holidayDate', 'dayOfWeek', 'holiday']);
        });
    })

    describe('bitwise operator', function() {
        var c;
        beforeEach(function() {
            c = controller();
            spyOn(c, 'hasWorkDay').and.callThrough();
        });
        it('should correctly find work days', function() {
            expect(c.hasWorkDay(1)).toBeTruthy();
            expect(c.hasWorkDay(2)).toBeTruthy();
            expect(c.hasWorkDay(4)).toBeTruthy();
            expect(c.hasWorkDay(8)).toBeTruthy();
            expect(c.hasWorkDay(16)).toBeTruthy();
            expect(c.hasWorkDay(32)).toBeFalsy();
            expect(c.hasWorkDay(64)).toBeFalsy();
        });
    });

    describe('bitwise operator', function() {
        var c;
        beforeEach(function() {
            c = controller();
            spyOn(c, 'hasWorkDay').and.callThrough();
        });
        it('should correctly find work days', function() {
            expect(c.hasWorkDay(1)).toBeTruthy();
            expect(c.hasWorkDay(2)).toBeTruthy();
            expect(c.hasWorkDay(4)).toBeTruthy();
            expect(c.hasWorkDay(8)).toBeTruthy();
            expect(c.hasWorkDay(16)).toBeTruthy();
            expect(c.hasWorkDay(32)).toBeFalsy();
            expect(c.hasWorkDay(64)).toBeFalsy();
        });
    });

    describe('add new public holiday', function () {
        it('should call modalService with add mode', function () {
            var c = controller();            
            c.onAddClick();

            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'BusinessdaysMaintenance',
                    mode: 'add'
                })));
        });
    });

    describe('edit public holiday', function () {
        it('should call modalService with edit mode', function () {
            var c = controller(); 
            spyOn(c, 'getSelectedItems').and.returnValue([4]);
            
            c.onEditClick();

            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'BusinessdaysMaintenance',
                    mode: 'edit'
                })));
        });
        it('should return if more than one record is selected for edit', function () {
            var c = controller(); 
            spyOn(c, 'getSelectedItems').and.returnValue([4, 6]);
            
            c.onEditClick();

            expect(modalService.openModal).not.toHaveBeenCalled();
        });
    });
    describe('delete public holiday', function () {
        it('should call notification service for delete', function () {
            var c = controller(); 
            spyOn(c, 'getSelectedItems').and.returnValue([4]);
            
            c.OnDeleteClick();

            expect(notificationService.confirm).toHaveBeenCalled();
        });
        it('should return if no record is selected for delete', function () {
            var c = controller(); 
            spyOn(c, 'getSelectedItems').and.returnValue({});
            
            c.OnDeleteClick();

            expect(notificationService.confirm).not.toHaveBeenCalled();
        });
    });
});