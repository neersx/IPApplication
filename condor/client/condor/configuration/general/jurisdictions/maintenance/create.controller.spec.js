describe('inprotech.configuration.general.jurisdictions.CreateJurisdictionController', function() {
    'use strict';

    var controller, hotKeys, uibModalInstance, notificationService, maintenanceService, promiseMock, jurisdictionsService;

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function() {
            jurisdictionsService = test.mock('jurisdictionsService', 'JurisdictionsServiceMock');
            maintenanceService = test.mock('jurisdictionMaintenanceService', 'JurisdictionMaintenanceServiceMock');
            notificationService = test.mock('notificationService', 'notificationServiceMock');
            uibModalInstance = test.mock('$uibModalInstance', 'ModalInstanceMock')
            hotKeys = test.mock('hotkeys');
            promiseMock = test.mock('promise');
        });
    });

    beforeEach(inject(function($controller) {
        controller = function(dependencies) {
            dependencies = angular.extend({}, dependencies);
            return $controller('CreateJurisdictionController', dependencies);
        };
    }));

    it('initialises the properties', function() {
        hotKeys.add = jasmine.createSpy('add() spy').and.callThrough();
        var c = controller();
        expect(c.cancel).toBeDefined();
        expect(c.disable).toBeDefined();
        expect(c.dismissAll).toBeDefined();
        expect(c.save).toBeDefined();
        expect(c.maintenance).toBeDefined();
        expect(c.formData.type).toBe("0");
        expect(hotKeys.add).toHaveBeenCalledWith({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: jasmine.any(Function)
        });
        expect(hotKeys.add).toHaveBeenCalledWith({
            combo: 'alt+shift+z',
            description: 'shortcuts.close',
            callback: jasmine.any(Function)
        });
    });

    describe('Disable saving', function() {
        var c;
        beforeEach(function() {
            c = controller();
        });
        it('if no changes have been made', function() {
            c.maintenance = {
                $dirty: false,
                $valid: true
            };
            var result = c.disable();
            expect(result).toBe(true);
        });
        it('if there are errors', function() {
            c.maintenance = {
                $dirty: true,
                $valid: false
            };
            var result = c.disable();
            expect(result).toBe(true);
        });
        describe('but Enable saving', function() {
            it('if changes have been made and there are no errors', function() {
                c.maintenance = {
                    $dirty: true,
                    $valid: true
                };
                var result = c.disable();
                expect(result).toBe(false);
            });
        });
    });


    describe('Cancelling', function() {
        it('dismisses the modal window', function() {
            var c = controller();
            c.cancel();
            expect(uibModalInstance.dismiss).toHaveBeenCalledWith('Cancel');
        })
    });

    describe('Discarding', function() {
        var c;
        beforeEach(function() {
            c = controller();
        });
        it('closes the dialog if not dirty', function() {
            c.maintenance = {
                $dirty: false
            };
            spyOn(c, 'cancel');
            c.dismissAll();
            expect(c.cancel).toHaveBeenCalled();
            expect(notificationService.discard).not.toHaveBeenCalled();
        });
        it('displays the confirmation dialog', function() {
            c.maintenance = {
                $dirty: true
            };
            spyOn(c, 'cancel');
            c.dismissAll();
            expect(notificationService.discard).toHaveBeenCalled();
        });
    });

    describe('Saving', function() {
        var c;
        beforeEach(function() {
            c = controller();
            c.formData = {
                id: 'abc'
            };
            maintenanceService.create = promiseMock.createSpy({
                data: {
                    result: 'success',
                    id: 'abc'
                }
            });
        });

        it('performs form validation where available', function() {
            var validate = jasmine.createSpy('validate');
            c.maintenance = {
                $validate: validate
            };
            c.save();
            expect(c.maintenance.$validate).toHaveBeenCalled();
        });

        it('does not save if there are errors', function() {
            c.maintenance = {
                $invalid: true
            };
            c.save();
            expect(maintenanceService.create).not.toHaveBeenCalled();
            expect(uibModalInstance.close).not.toHaveBeenCalled();
        });

        it('calls the service to create the new record', function() {
            c.save();
            expect(maintenanceService.create).toHaveBeenCalledWith({
                id: 'abc'
            });
            expect(jurisdictionsService.newId).toBe('abc');
            expect(uibModalInstance.close).toHaveBeenCalled();
        });

        describe('handles', function() {
            it('server validation errors', function() {
                maintenanceService.create = promiseMock.createSpy({
                    data: {
                        result: {
                            errors: [{
                                topic: 'whatever',
                                field: 'code',
                                id: 'abc'
                            }]
                        }
                    }
                });
                c.save();
                expect(maintenanceService.create).toHaveBeenCalledWith({
                    id: 'abc'
                });
                expect(c.errors).toEqual([{
                    topic: 'whatever',
                    field: 'code',
                    id: 'abc'
                }]);
                expect(notificationService.alert).toHaveBeenCalledWith({
                    title: 'modal.unableToComplete',
                    message: 'whatever',
                    messageParams: {
                        id: 'abc'
                    },
                    errors: []
                });
                expect(jurisdictionsService.newId).not.toBeDefined();
                expect(uibModalInstance.close).not.toHaveBeenCalled();
            });
        });

    });
});