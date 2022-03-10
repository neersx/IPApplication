namespace inprotech.portfolio.cases {
    describe('inprotech.portfolio.cases case name link controller', () => {
        'use strict';

        let controller, service: ICaseviewNamesService;

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.portfolio.cases']);
                service = $injector.get<ICaseviewNamesService>('caseviewNamesServiceMock');
            });

            inject(() => {
                controller = () => {
                    return new CaseNameLinkController(service);
                };
            });
        });

        describe('initialise with show email link', () => {
            it('should resolve email template from server', () => {

                let expected = {};
                (<any>service).getFirstEmailTemplate.returnValue = expected;

                let c = controller();
                c.caseKey = 1;
                c.nameType = 'a';
                c.showEmailLink = true;
                c.$onInit();

                expect(c.email).toEqual(expected);
                expect(service.getFirstEmailTemplate).toHaveBeenCalledWith(1, 'a');
            });
        });

        describe('initialise without show email link', () => {
            it('should not resolve email template from server', () => {

                let c = controller();
                c.caseKey = 1;
                c.nameType = 'a';
                c.showEmailLink = false;
                c.$onInit();

                expect(service.getFirstEmailTemplate).not.toHaveBeenCalled();
            });
        });
    });
}