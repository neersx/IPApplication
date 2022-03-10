'use strict';

describe('Inprotech.Integration.externalApplicationTokenEditController', function() {

    var c, modalInstance, notificationService, http;
    beforeEach(module('inprotech.classic'));
    beforeEach(
        module(function() {
            test.mock('modalService');
            http = test.mock('$http', 'httpMock');
            test.mock('kendoGridBuilder');
            notificationService = test.mock('notificationService');
            modalInstance = test.mock('$uibModalInstance', 'ModalInstanceMock');
        }));

    var fixture = {};

    beforeEach(
        inject(
            function($controller, $rootScope, $location, $injector) {

                var httpBackend = $injector.get('$httpBackend');

                fixture = {
                    location: $location,
                    httpBackend: httpBackend,
                    viewData: {
                        externalApplicationId: '1',
                        name: 'Trinogy',
                        code: 'Trinogy',
                        token: 'AB121',
                        isActive: true,
                        expiryDate: '18-Dec-2015',
                        source: 'xml'
                    },
                    saveResponse: {
                        statusCode: 200,
                        result: {
                            viewData: {
                                result: 'success'
                            }
                        }
                    },
                    controller: function() {
                        fixture.scope = $rootScope.$new();

                        httpBackend.whenPOST('api/externalApplication/externalApplicationToken/save')
                            .respond(fixture.saveResponse.statusCode || 200, fixture.saveResponse.result);

                        c = $controller('externalApplicationTokenEditController', {
                            $location: $location,
                            $scope: fixture.scope,
                            options: {
                                viewData: fixture.viewData
                            }
                        });
                    }
                };
            }
        )
    );

    it('should set up external system token', function() {
        fixture.controller();
        expect(c.externalApp.name).toBe('Trinogy');
        expect(c.form).toBeDefined();
        expect(c.minStartDate).toBeDefined();
        expect(c.disable).toBeDefined();
        expect(c.dismissAll).toBeDefined();
        expect(c.save).toBeDefined();
        expect(c.externalApp).toBeDefined();
        expect(c.selectedDate).toBeDefined();
    });

    it('should call correct endpoint when saving', function() {

        fixture.controller();
        http.post.returnValue = {
            result: {
                viewData: {
                    result: 'success'
                }
            }
        }
        c.save();
        expect(http.post).toHaveBeenCalledWith('api/externalApplication/externalApplicationToken/save', c.externalApp);
        expect(notificationService.success).toHaveBeenCalled();
        expect(modalInstance.close).toHaveBeenCalledWith(true);
    });

    it('should disable the save button', function() {
        fixture.controller();
        setForm(true, true);
        expect(c.disable()).toBeFalsy();
        setForm(true, false);
        expect(c.disable()).toBeTruthy();
        setForm(false, true);
        expect(c.disable()).toBeTruthy();
    });

    it('should close the modal if no pending changes', function() {
        fixture.controller();
        setForm(false, true);
        c.dismissAll();
        expect(modalInstance.close).toHaveBeenCalledWith(false);
    });

    it('should close the modal after asking for confirmation if pending changes', function() {
        fixture.controller();
        setForm(true, true);
        c.dismissAll();
        expect(notificationService.discard).toHaveBeenCalled();
        expect(modalInstance.close).not.toHaveBeenCalled();

        notificationService.discard.confirmed = true;
        c.dismissAll();
        expect(notificationService.discard).toHaveBeenCalled();
        expect(modalInstance.close).toHaveBeenCalledWith(false);

    });

    function setForm(dirty, valid) {
        c.form = {

            $dirty: dirty,
            $valid: valid,
            $validate: function() {
                return valid;
            },
            $invalid: !valid

        }
    }
});