'use strict';

namespace inprotech.portfolio.cases {
    describe('case debtor restrictions indicator controller', function () {

        let controller: () => DebtorRestrictionFlagController, service: any;

        beforeEach(function () {
            angular.mock.module('inprotech.portfolio.cases');
        });

        beforeEach(function () {
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.portfolio.cases']);
                service = $injector.get<IDebtorRestrictionsService>('debtorRestrictionsServiceMock');
            });

            inject(function () {
                controller = (): DebtorRestrictionFlagController => {
                    return new DebtorRestrictionFlagController(service);
                };
            });
        });

        describe('initialize', function () {
            it('should get restriction details from the service', () => {
                service.getRestrictions.returnValue = { id: 1, description: 'a', severity: 'b' };
                let c = controller();
                c.debtor = 1;
                c.$onInit();
                expect(c.debtor).toEqual(1);
                expect(c.description).toEqual('a');
                expect(c.severity).toEqual('b');
            });

            it('should do nothing if debtor not set', () => {
                let c = controller();
                c.debtor = undefined;
                c.$onInit();
                expect(c.debtor).toBeUndefined();
                expect(c.description).toBeUndefined();
                expect(c.severity).toBeUndefined();
            });
        });
    });
}