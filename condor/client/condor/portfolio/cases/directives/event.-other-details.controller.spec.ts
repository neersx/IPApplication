namespace inprotech.portfolio.cases {
    describe('inprotech.portfolio.cases.eventOtherDetailsController', () => {
        'use strict'

        let controller: (extend?: any) => EventOtherDetailsController

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(inject(($rootScope: ng.IRootScopeService) => {
            controller = function (extend?: any) {
                let c = new EventOtherDetailsController();
                c.event = {
                    notes: [{
                        cycle: 1,
                        eventId: -102,
                        eventText: '--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalan test notes 2\n--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalantest notes',
                        isDefault: false,
                        noteType: 1
                    }]
                };
                return c;
            };
        }));

        describe('initialise view', () => {
            let c: EventOtherDetailsController;
            it('should initialise', () => {
                c = controller();
                expect(c.event).toEqual({
                    notes: [{
                        cycle: 1,
                        eventId: -102,
                        eventText: '--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalan test notes 2\n--- Notes entered by Grey, George on 03-Apr-2018 at 1:32 PM:\nalantest notes',
                        isDefault: false,
                        noteType: 1
                    }]
                });
            });
        })
    })
}