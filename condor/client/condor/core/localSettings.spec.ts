'use strict';

namespace inprotech.portfolio.cases {
    describe('local settings', function () {

        let store, controller;

        beforeEach(function () {

            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
                store = $injector.get('storeMock');
            });

            inject(function ($rootScope) {
                controller = new inprotech.core.LocalSettings(store);
            });
        });

        it('should have settings object generated with correct methods', function () {
            let c = controller;
            expect(c).toBeDefined();
            expect(c.Keys.caseView.actionPageNumber).toBeDefined();
            expect(c.Keys.caseView.actionPageNumber.getLocal).toEqual('5');
            c.Keys.caseView.actionPageNumber.setLocal(20);
            expect(store.local.set).toHaveBeenCalledWith('caseView.actionPageNumber', 20)
        });

        it('should accept suffix', function () {
            let c = controller;
            expect(c).toBeDefined();
            expect(c.Keys.caseView.names.pageNumber).toBeDefined();
            expect(c.Keys.caseView.names.pageNumber.getLocal).toEqual('10');
            c.Keys.caseView.names.pageNumber.setLocal(20, 'test');
            expect(store.local.set).toHaveBeenCalledWith('caseView.names.pageNumbertest', 20)
            c.Keys.caseView.names.pageNumber.getLocalwithSuffix('test');
            expect(store.local.get).toHaveBeenCalledWith('caseView.names.pageNumbertest')
        });
    });
}