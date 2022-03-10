'use strict';

namespace Inprotech.Integration.PtoAccess {

    describe('newUsptoPrivatePairSponsorshipController', function () {
        let controller, modalInstance, notificationService, sponsorshipService, modalService, hotkeys, q, rootScope;
        beforeEach(function () {
            angular.mock.module('inprotech.classic');
            angular.mock.module('Inprotech.Integration.PtoAccess');
        });

        beforeEach(
            angular.mock.module(function () {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);
                modalInstance = $injector.get('ModalInstanceMock');
                modalService = $injector.get('modalServiceMock');
                hotkeys = $injector.get('hotkeysMock');
                notificationService = $injector.get('notificationServiceMock');
                sponsorshipService = $injector.get<ISponsorshipService>('sponsorshipServiceMock');
            }));

        beforeEach(
            inject(function ($rootScope: ng.IRootScopeService, $q: ng.IQService) {
                controller = (data?: any) => {
                    return new NewUsptoPrivatePairSponsorshipController(
                        modalInstance, hotkeys, notificationService, modalService, sponsorshipService,
                        {
                            data: data || {
                                item: null,
                                customerNumbers: '1110098, 988444'
                            }
                        });
                };
                q = $q;
                rootScope = $rootScope;
            })
        );

        let c: NewUsptoPrivatePairSponsorshipController;
        describe('New Sponsorship', () => {
            beforeEach(() => {
                c = controller();
                c.form = jasmine.createSpyObj('ng.IFormController', ['$validate', '$dirty']);
                rootScope.$apply();
            });

            it('should be in ready state', function () {
                expect(c.sponsorship).toBeDefined();
                expect(c.disable).toBeDefined();
                expect(c.dismissAll).toBeDefined();
                expect(c.save).toBeDefined();
                expect(c.afterSave).toBeDefined();
                expect(c.initShortcuts).toBeDefined();
                expect(c.isSaving).toBeFalsy();
                expect(c.serviceInfo).toBeUndefined();
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
                sponsorshipService.addOrUpdate.returnValue = {
                    data: {
                        isSuccess: true
                    }
                };
                c.save();

                expect(c.isSaving).toBeFalsy();
                expect(sponsorshipService.addOrUpdate).not.toHaveBeenCalled();
            });

            it('should save sponsorship', function () {
                setForm(true, true);
                sponsorshipService.addOrUpdate.returnValue = {
                    data: {
                        isSuccess: true
                    }
                };

                c.save();

                expect(c.isSaving).toBeFalsy();
                expect(sponsorshipService.addOrUpdate).toHaveBeenCalled();
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


        describe('Update Sponsorship', () => {
            it('should set ServiceInfo', () => {
                c = controller({
                    item: {
                        sponsorName: 'test',
                        sponsoredEmail: 'test@test.com',
                        customerNumbers: '1110098, 988444',
                        serviceId: 'service001'
                    },
                    customerNumbers: '1110098, 988444',
                    clientId: 'client001'
                });

                expect(c.serviceInfo).toEqual('client001 | service001');
            });
        });
    })
}