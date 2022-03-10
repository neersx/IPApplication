describe('inprotech.processing.exchange.ExchangeConfigurationController', function () {
    'use strict';

    var scope, controller, service, notificationService, extObjFactory, promiseMock, stateService;

    beforeEach(function () {
        module('inprotech.processing.exchange');
        module(function ($provide) {
            var $injector = angular.injector(['inprotech.mocks.processing.exchange', 'inprotech.core.extensible', 'inprotech.mocks.components.notification', 'inprotech.mocks.core']);
            service = $injector.get('ExchangeSettingsServiceMock');
            $provide.value('exchangeSettingsService', service);

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            extObjFactory = $injector.get('ExtObjFactory');
            $provide.value('ExtObjFactory', extObjFactory);

            promiseMock = $injector.get('promiseMock');

            stateService = test.mock('$state', 'stateMock');
        });
    });

    beforeEach(inject(function ($controller) {
        controller = function (dependencies) {
            scope = {};
            dependencies = angular.extend({
                $scope: scope,
                viewData: {},
                ExtObjFactory: extObjFactory,
                $state: stateService
            }, dependencies);

            var c = $controller('ExchangeConfigurationController', dependencies);
            c.$onInit();
            return c;
        };
    }));

    describe('initialisation', function () {
        it('should initialise the properties', function () {
            var viewData = {
                settings: {
                    serverUrl: 'abc',
                    exchangeGraph: { tenantId: 't123', clientId: 'c123', clientSecret: 'cs123' }
                },
                passwordExists: 'xyz',
                clientSecretExists: true,
                hasValidSettings: 'asd'
            };
            var c = controller({
                viewData: viewData
            });
            expect(c.form).toBeDefined();
            expect(c.formData).toBeDefined();
            expect(c.passwordExists).toEqual(viewData.passwordExists);
            expect(c.clientSecretExists).toEqual(viewData.clientSecretExists);
            expect(c.statusCheckInProgress).toEqual(false);
            expect(c.hasValidSettings).toEqual(viewData.hasValidSettings);
        });
    })

    describe('saving', function () {
        var viewData = {
            settings: {
                serverUrl: 'abc',
                exchangeGraph: { tenantId: 't123', clientId: 'c123', clientSecret: 'cs123' }
            }
        };
        it('should not proceed if invalid', function () {
            var c = controller({
                viewData: viewData
            });
            c.form.$validate = jasmine.createSpy().and.returnValue(false);
            c.form.userName = {
                $valid: false
            };
            c.form.server = {
                $valid: false
            };
            c.save();
            expect(service.save).not.toHaveBeenCalled();
        });
        it('should not proceed if password exists and is server is invalid', function () {
            var response = {
                data: {
                    result: {
                        status: 'abc'
                    }
                }
            };
            var c = controller({
                viewData: {
                    passwordExists: true,
                    settings: {
                        serverUrl: 'abc',
                        exchangeGraph: { tenantId: 't123', clientId: 'c123', clientSecret: 'cs123' }
                    }
                }
            });
            c.formData.isDirty = jasmine.createSpy().and.returnValue(true);
            c.form.$validate = jasmine.createSpy().and.returnValue(false);
            c.form.userName = {
                $valid: true
            };
            c.form.server = {
                $valid: false
            };
            service.save = promiseMock.createSpy(response);
            c.save();
            expect(service.save).not.toHaveBeenCalled();
        });
        it('should not proceed if password exists and is userName is invalid', function () {
            var response = {
                data: {
                    result: {
                        status: 'abc'
                    }
                }
            };
            var c = controller({
                viewData: {
                    passwordExists: true,
                    settings: {
                        serverUrl: 'abc',
                        exchangeGraph: { tenantId: 't123', clientId: 'c123', clientSecret: 'cs123' }
                    }
                }
            });
            c.formData.isDirty = jasmine.createSpy().and.returnValue(true);
            c.form.$validate = jasmine.createSpy().and.returnValue(false);
            c.form.userName = {
                $valid: false
            };
            c.form.server = {
                $valid: true
            };
            c.form.userName = {
                $valid: false
            };
            service.save = promiseMock.createSpy(response);
            c.save();
            expect(service.save).not.toHaveBeenCalled();
        });
        it('should proceed if valid, and password has not been changed', function () {
            var response = {
                data: {
                    result: {
                        status: 'abc'
                    }
                }
            };
            var c = controller({
                viewData: {
                    passwordExists: true,
                    settings: {
                        serverUrl: 'abc',
                        exchangeGraph: { tenantId: 't123', clientId: 'c123', clientSecret: 'cs123' }
                    }
                }
            });
            c.form.$validate = jasmine.createSpy().and.returnValue(true);
            c.formData.isDirty = jasmine.createSpy().and.returnValue(false);
            service.save = promiseMock.createSpy(response);
            c.form.userName = {
                $valid: true
            };
            c.form.server = {
                $valid: true
            };
            c.passwordExists = true;
            c.save();
            expect(service.save).toHaveBeenCalled();
        });
        it('should call the service correctly', function () {
            var response = {
                data: {
                    result: {
                        status: 'abc'
                    }
                }
            };
            var c = controller({
                viewData: viewData
            });
            c.form.$validate = jasmine.createSpy().and.returnValue(true);
            service.save = promiseMock.createSpy(response);
            c.form.userName = {
                $valid: true
            };
            c.form.server = {
                $valid: true
            };
            c.passwordExists = true;
            c.save();
            expect(service.save).toHaveBeenCalled();
        });
        describe('then', function () {
            var c;
            beforeEach(function () {
                viewData = {
                    settings: {
                        serverUrl: 'abc',
                        exchangeGraph: { tenantId: 't123', clientId: 'c123', clientSecret: 'cs123' }
                    }
                };
                c = controller({
                    viewData: viewData
                });
                c.form.$validate = jasmine.createSpy().and.returnValue(true);
            });
            it('should display success notification if successful', function () {
                var response = {
                    data: {
                        result: {
                            status: 'success'
                        }
                    }
                };
                service.save = promiseMock.createSpy(response);
                c.form.userName = {
                    $valid: true
                };
                c.form.server = {
                    $valid: true
                };
                c.passwordExists = true;
                c.save();
                expect(service.save).toHaveBeenCalled();
                expect(notificationService.success).toHaveBeenCalled();
                expect(stateService.reload).toHaveBeenCalled();
            });
            it('should not display success notification if unsuccessful', function () {
                var response = {
                    data: {
                        result: {
                            status: 'abc'
                        }
                    }
                };
                service.save = promiseMock.createSpy(response);
                c.form.userName = {
                    $valid: true
                };
                c.form.server = {
                    $valid: true
                };
                c.passwordExists = true;
                c.save();
                expect(service.save).toHaveBeenCalled();
                expect(notificationService.success).not.toHaveBeenCalled();
                expect(stateService.reload).not.toHaveBeenCalled();
            });
        });
    });

    describe('checkStatus', function () {
        it('sets connection status flags accordingly', function () {
            var response = {
                data: {
                    result: true
                }
            };
            var viewData = {
                settings: {
                    serverUrl: 'abc',
                    exchangeGraph: { tenantId: 't123', clientId: 'c123', clientSecret: 'cs123' }
                },
                passwordExists: 'xyz',
                hasValidSettings: 'asd'
            };
            var c = controller({
                viewData: viewData
            });

            service.checkStatus = promiseMock.createSpy(response);
            c.checkStatus();

            expect(service.checkStatus).toHaveBeenCalled();
            expect(c.isConnectionOk).toBe(true);
            expect(c.isConnectionFail).toBe(false);
            expect(c.statusCheckInProgress).toBe(false);

        });
    });
});
