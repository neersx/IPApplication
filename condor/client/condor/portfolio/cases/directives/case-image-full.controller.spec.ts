namespace inprotech.portfolio.cases {
    describe('inprotech.portfolio.cases.caseImageFull', () => {
        'use strict';

        let c: CaseImageFullController;
        let controller: (options ?: any) => CaseImageFullController, uibModalInstance: any;

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
                uibModalInstance = $injector.get('ModalInstanceMock');
                $provide.value('$uibModalInstance', uibModalInstance);

            });
        });

        beforeEach(inject(($rootScope: ng.IRootScopeService) => {
            controller = function(options ? ) {
                options = angular.extend({
                    imageKey: 456,
                    imageTitle: 'abcd123',
                    imageDesc: 'abcdDesc'
                }, options);

                let cont = new CaseImageFullController(uibModalInstance, options);
                return cont;
            };
        }));

        describe('initialise view', () => {
            it('should initialise variables', () => {
                c = controller();
                expect(c.imageKey).toBe(456);
                expect(c.imageTitle).toBe('abcd123');
                expect(c.imageDesc).toBe('abcdDesc');
                expect(c.titleLimit).toBe(80);
            });
        });

        describe('closing the dialog', () => {
            it('should destroy the modal', () => {
                c = controller();
                c.close();
                expect(uibModalInstance.close).toHaveBeenCalled();
            })
        })
    });
}