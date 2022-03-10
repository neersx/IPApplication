namespace inprotech.portfolio.cases {
    describe('inprotech.portfolio.cases.caseSummaryController', () => {
        'use strict'

        let controller: (extend ?: any) => CaseSummaryController, scope: ng.IScope

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(inject(($rootScope: ng.IRootScopeService) => {
            scope = < ng.IScope > $rootScope.$new();
            angular.extend(scope, {
                viewData: {
                    caseKey: 123,
                    imageKey: 'abcxyz123'
                },
                screenControl: {
                    abc: 'xyz'
                },
                isExternal: true,
                withImage: true
            });
            controller = function(extend ?: any) {
                angular.extend(scope, extend);
                let c = new CaseSummaryController(scope, {});
                return c;
            };
        }));

        describe('initialise view', () => {
            let c: CaseSummaryController;
            it('should initialise screen control and viewdata', () => {
                c = controller();
                expect(c.screenControl).toBeDefined();
                expect(c.viewData).toBeDefined();
                expect(c.isExternal).toBe(true);
                expect(c.hasImage).toBe(true);
            });
        });
    });
}