namespace inprotech.accounting.vat {
    describe('hmrc configuration settings', () => {
        'use strict'
        let controller: (viewData ?: any) => AccountingHmrcSettingsController,
            service: any,
            notificationService: any,
            promiseMock: any;

        beforeEach(() => {
            angular.mock.module('inprotech.accounting.vat');
            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector([
                    'inprotech.mocks',
                    'inprotech.mocks.core',
                    'inprotech.mocks.components.notification'
                ]);

                service = $injector.get('VatReturnsServiceMock');
                notificationService = $injector.get('notificationServiceMock');
                $provide.value('notificationService', notificationService);
                promiseMock = $injector.get < any > ('promiseMock');
            });
        });

        beforeEach(() => {
            inject(() => {
                controller = (viewData ?: any) => {
                    let c = new AccountingHmrcSettingsController(service, notificationService);
                    angular.extend(c, viewData);
                    return c;
                };
            });
        });

        describe('initialise', () => {
            it('should initialise the page', () => {
                let c = controller({
                    viewData: {
                        hmrcSettings: {
                            hmrcApplicationName: 'Inprotech-Internal',
                            clientId: 'client',
                            redirectUri: 'http://test.au/vat/settings',
                            clientSecret: '8489jkfkljk4',
                            isProduction: true
                        }
                    }
                });
                expect(c.viewData).toBeDefined();
                expect(c.initialData).toBeDefined();

                c.$onInit();

                expect(c.initialData.hmrcApplicationName).toEqual(c.viewData.hmrcSettings.hmrcApplicationName);
                expect(c.initialData.clientId).toEqual(c.viewData.hmrcSettings.clientId);
                expect(c.initialData.clientSecret).toEqual(c.viewData.hmrcSettings.clientSecret);
                expect(c.initialData.isProduction).toEqual(c.viewData.hmrcSettings.isProduction);
                expect(c.initialData.redirectUri).toEqual(c.viewData.hmrcSettings.redirectUri);
            });
        });

        describe('when saved', () => {
            it('should call the save api', () => {
                service.save = promiseMock.createSpy({
                    data: {
                        result: {
                            status: 'success'
                        }
                    }
                });

                let c = controller({
                    viewData: {
                        hmrcSettings: {
                            hmrcApplicationName: 'Inprotech-Internal',
                            clientId: 'client',
                            redirectUri: 'http://test.au/vat/settings',
                            clientSecret: '8489jkfkljk4',
                            isProduction: true
                        }
                    }
                });
                c.form = {
                    $setPristine: jasmine.createSpy().and.callThrough()
                };

                c.save();

                expect(c.service.save).toHaveBeenCalledWith(c.viewData.hmrcSettings);
                expect(c.form.$setPristine).toHaveBeenCalled();
                expect(notificationService.success).toHaveBeenCalled();
            });
        });

        describe('when discarded', () => {
            it('should reset to intial data', () => {
                let disData = new HmrcSettingsModel('Inprotech-Internal', 'disClient', 'http://test.au/vat/discardedsettings', 'disseceret', false);
                let c = controller({
                    viewData: {
                        hmrcSettings: {}
                    }
                });
                c.form = {
                    $setPristine: jasmine.createSpy().and.callThrough()
                };
                c.initialData = disData;
                c.viewData.hmrcSettings = {
                    hmrcApplicationName: 'Inprotech-Internal',
                    clientId: 'client',
                    redirectUri: 'http://test.au/vat/settings',
                    clientSecret: '8489jkfkljk4',
                    isProduction: true
                }

                c.discard();

                expect(c.form.$setPristine).toHaveBeenCalled();
                expect(c.viewData.hmrcSettings.hmrcApplicationName).toEqual(c.initialData.hmrcApplicationName);
                expect(c.viewData.hmrcSettings.clientId).toEqual(c.initialData.clientId);
                expect(c.viewData.hmrcSettings.clientSecret).toEqual(c.initialData.clientSecret);
                expect(c.viewData.hmrcSettings.redirectUri).toEqual(c.initialData.redirectUri);
                expect(c.viewData.hmrcSettings.isProduction).toEqual(c.initialData.isProduction);
            });
        });
    });
}