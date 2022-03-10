'use strict';

namespace inprotech.portfolio.cases {
    describe('case view names expanded details controller', () => {

        let controller, service: ICaseviewNamesService, displayableFields: DisplayableNameTypeFieldsHelper;

        beforeEach(() => {
            angular.mock.module('inprotech.portfolio.cases');
            angular.mock.module(() => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks', 'inprotech.mocks.portfolio.cases']);
                service = $injector.get<ICaseviewNamesService>('caseviewNamesServiceMock');
                displayableFields = new DisplayableNameTypeFieldsHelper();
            });

            inject(() => {
                controller = (caseId: number, details: any) => {
                    let c = new NameDetailsController(displayableFields, service);
                    c.caseId = caseId;
                    c.details = details || {};
                    c.$onInit();
                    return c;
                };
            });
        });

        describe('initialise without email', () => {
            it('should not resolve email template', () => {
                controller(1, {
                    email: null
                });
                expect(service.getFirstEmailTemplate).not.toHaveBeenCalled();
            });
        });

        describe('initialise with email', () => {
            it('should resolve email template', () => {
                (<any>service).getFirstEmailTemplate.returnValue = {
                    recipientCopiesTo: [],
                    subject: 'Regarding abc',
                    body: 'Regarding abc body'
                };
                controller(1, {
                    typeId: 'a',
                    sequence: 20,
                    email: 'someone@myorg.com'
                });
                expect(service.getFirstEmailTemplate).toHaveBeenCalledWith(1, 'a', 20);
            });
            it('should set email model with email with the email template', () => {
                (<any>service).getFirstEmailTemplate.returnValue = {
                    recipientCopiesTo: ['one@two.three.com'],
                    subject: 'Regarding abc',
                    body: 'Regarding abc body'
                };
                let c = controller(1, {
                    typeId: 'a',
                    sequence: 20,
                    email: 'someone@myorg.com'
                });
                expect(c.email).toEqual({
                    recipientEmail: 'someone@myorg.com',
                    recipientCopiesTo: ['one@two.three.com'],
                    subject: 'Regarding abc',
                    body: 'Regarding abc body'
                });
            });
        })
    });
}