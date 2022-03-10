namespace inprotech.portfolio.cases {
    describe('inprotech.portfolio.cases.duedate', () => {
        'use strict';

        let c: DueDateController;
        let controller: () => DueDateController;
        let scope: any;

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(inject(($rootScope: ng.IRootScopeService) => {
            scope = $rootScope.$new();
            controller = function () {
                let cont = new DueDateController(scope);
                return cont;
            };
        }));

        describe('initialise view', () => {
            it('should setup a watch on date', () => {
                spyOn(scope, '$watch');
                c = controller();
                c.$onInit();
                expect(scope.$watch).toHaveBeenCalledWith('vm.date', jasmine.any(Function));
            });
        });

        describe('due date is overdue check', () => {
            it('should return true if date is overdue', () => {
                scope.$watch = jasmine.createSpy('watchSpy');
                let now: Date = new Date();
                c = controller();
                c.$onInit();
                let setOverdue = scope.$watch.calls.first().args[1];
                expect(setOverdue).toBeDefined();
                expect(c.isOverdue).not.toBeDefined(false);

                // due date is today
                c.date = now.toISOString()
                setOverdue();
                expect(c.isOverdue).toEqual(true);

                // due date is passed
                now.setMonth(now.getMonth() - 1);
                c.date = now.toISOString();
                setOverdue();
                expect(c.isOverdue).toEqual(true);
            });

            it('should return false if due date is in the future', () => {
                scope.$watch = jasmine.createSpy('watchSpy');
                let pastDate: Date = new Date('2099-01-01');
                c = controller();
                c.$onInit();
                let setOverdue = scope.$watch.calls.first().args[1];
                expect(setOverdue).toBeDefined();
                expect(c.isOverdue).not.toBeDefined(false);

                c.date = pastDate.toISOString();
                setOverdue();
                expect(c.isOverdue).toEqual(false);
            });
        });
    });
}