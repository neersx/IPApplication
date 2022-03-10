'use strict';

namespace Inprotech.Integration.PtoAccess {

    describe('updateUsptoAccountDetailsController', function () {
        let controller, modalInstance, notificationService, sponsorshipService, hotkeys, q, rootScope;

        beforeEach(function () {
            angular.mock.module('inprotech.classic');
            angular.mock.module('Inprotech.Integration.PtoAccess');
        });

        beforeEach(
            angular.mock.module(function () {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
                modalInstance = $injector.get('ModalInstanceMock');
                hotkeys = $injector.get('hotkeysMock');
                notificationService = $injector.get('notificationServiceMock');
                sponsorshipService = $injector.get<ISponsorshipService>('sponsorshipServiceMock');
            }));

        beforeEach(
            inject(function ($rootScope: ng.IRootScopeService, $q: ng.IQService) {
                controller = (clientId?: string) => {
                    return new UpdateUsptoAccountDetailsController(
                        modalInstance, hotkeys, notificationService, sponsorshipService,
                        {
                            data: {
                                clientId: clientId || 'axerf12345'
                            }
                        });
                };
                q = $q;
                rootScope = $rootScope;
            }));

        let c: UpdateUsptoAccountDetailsController;
        describe('Update Global Account Settings', () => {
            beforeEach(() => {
                c = controller();
                c.form = jasmine.createSpyObj('ng.IFormController', ['$validate', '$dirty']);
                rootScope.$apply();
            });

            it('sets the account id', function () {
                expect(c.serviceInfo).toEqual('axerf12345');
                expect(c.isSaving).toBe(false);
            });

            it('should disable the save button', function () {
                setForm(true, true);
                expect(c.disable()).toBeFalsy();
                setForm(true, false);
                expect(c.disable()).toBeTruthy();
                setForm(false, true);
                expect(c.disable()).toBeTruthy();
            });

            it('should close the modal if no pending changes', function () {
                setForm(false, true);
                c.dismissAll();
                expect(modalInstance.close).toHaveBeenCalledWith(false);
            });

            it('should close the modal after asking for confirmation if pending changes', function () {
                setForm(true, true);
                c.dismissAll();
                expect(notificationService.discard).toHaveBeenCalled();
                expect(modalInstance.close).not.toHaveBeenCalled();

                notificationService.discard.confirmed = true;
                c.dismissAll();
                expect(notificationService.discard).toHaveBeenCalled();
                expect(modalInstance.close).toHaveBeenCalledWith(false);

            });

            it('should not save if required data is not provided', function () {
                setForm(true, false);
                sponsorshipService.updateAccountSettings.returnValue = {
                    data: {
                        isSuccess: true
                    }
                };
                c.save();

                expect(c.isSaving).toBeFalsy();
                expect(notificationService.confirm).not.toHaveBeenCalled();
                expect(sponsorshipService.updateAccountSettings).not.toHaveBeenCalled();
            });

            it('should save settings', function () {
                setForm(true, true);
                sponsorshipService.updateAccountSettings.returnValue = {
                    data: {
                        isSuccess: true
                    }
                };

                c.save();

                expect(c.isSaving).toBeFalsy();
                expect(notificationService.confirm).toHaveBeenCalled();
                expect(sponsorshipService.updateAccountSettings).toHaveBeenCalled();
                expect(modalInstance.close).toHaveBeenCalledWith(true);
                expect(notificationService.success).toHaveBeenCalled();
            });

            function setForm(dirty, valid) {
                c.form.$dirty = dirty;
                c.form.$valid = valid;
                c.form.$invalid = !valid;
                rootScope.$apply();
            }
        });
    });
}