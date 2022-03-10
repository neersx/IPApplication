namespace inprotech.portfolio.cases {
    describe('inprotech.portfolio.cases.eventNoteDetailsController', () => {
        'use strict'

        let controller: (extend?: any) => EventNoteDetailsController, scope: ng.IScope, kendoGridBuilder, $timeout

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(inject(($rootScope: ng.IRootScopeService) => {
            scope = <ng.IScope>$rootScope.$new();
            $timeout = jasmine.createSpy('$timeout');
            controller = function (extend?: any) {
                angular.extend(scope, extend);
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.portfolio.cases']);
                kendoGridBuilder = $injector.get('kendoGridBuilderMock');
                let c = new EventNoteDetailsController(scope, kendoGridBuilder, $timeout);
                c.notes = [{
                    cycle: 1,
                    eventId: -102,
                    eventText: '--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalan test notes 2\n--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalantest notes',
                    isDefault: false,
                    noteType: 1
                }];
                c.categories = [{
                    description: 'Discription',
                    code: 1
                }, {
                    description: 'NullDiscription',
                    code: null
                }];
                return c;
            };
        }));

        describe('initialise view', () => {
            let c: EventNoteDetailsController;
            it('should initialise', () => {
                c = controller();
                c.$onInit();
                expect(c.gridOptions).toBeDefined();
                expect(c.notes).toEqual([{
                    cycle: 1,
                    eventId: -102,
                    eventText: '--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalan test notes 2\n--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalantest notes',
                    isDefault: false,
                    noteType: 1
                }]);
            });

            it('should filter categorie', () => {
                c = controller();
                c.$onInit();

                expect(c.filteredCategories).toEqual([{
                    description: 'Discription',
                    code: 1
                }])
            });

            it('should create event note items', () => {
                c = controller();
                c.$onInit();

                expect(c.eventTextItems).toEqual([
                    new EventNote('--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalan test notes 2', 1, 'Discription'),
                    new EventNote('--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalantest notes', 1, 'Discription')
                ]);
            });
        });
    })
}