'use strict';

describe('Inprotech.Integration.externalApplicationTokenController', function() {

    var c, http, notificationService, modalService;
    beforeEach(module('inprotech.classic'));
    beforeEach(
        module(function() {
            modalService = test.mock('modalService');
            http = test.mock('$http', 'httpMock');
            test.mock('kendoGridBuilder');
            notificationService = test.mock('notificationService');
        }));

    var fixture = {};

    beforeEach(
        inject(
            function($controller, $rootScope, $injector) {

                var httpBackend = $injector.get('$httpBackend');

                fixture = {
                    httpBackend: httpBackend,
                    viewData: {
                        externalApps: [{
                            id: '1',
                            name: 'Trinogy',
                            code: 'Trinogy',
                            token: 'AB121',
                            createdOn: '2013-12-18T11:51:39.7599042+11:00',
                            createdBy: '-487',
                            isActive: true,
                            expiryDate: null
                        }]
                    },
                    controller: function() {
                        fixture.scope = $rootScope.$new();

                        c = $controller('externalApplicationTokenController', {
                            $scope: fixture.scope,
                            viewInitialiser: {
                                viewData: fixture.viewData
                            }
                        });
                        c.$onInit();
                    }
                };
            }
        )
    );

    it('should set up external systems list', function() {
        fixture.controller();
        expect(c.externalApps).toBeDefined();
        expect(c.externalApps.length).toBe(1);
        expect(c.generateToken).toBeDefined();
        expect(c.editExternalApp).toBeDefined();
        expect(c.gridOptions).toBeDefined();
        expect(c.externalApps).toBeDefined();
    });

    it('should generate token when requested.', function() {
        fixture.controller();
        var externalApp = _.first(c.externalApps);

        http.post.returnValue = {
            viewData: {
                result: 'success',
                token: '2345',
                isActive: true,
                expiryDate: null

            }
        };
        c.generateToken(externalApp.id);

        expect(http.post).toHaveBeenCalledWith('api/externalApplication/externalApplicationToken/generateToken?externalApplicationId=' + externalApp.id,void 0);
        expect(notificationService.success).toHaveBeenCalled();

        externalApp = _.first(c.externalApps)
        expect(externalApp.token).toBe('2345');
        expect(externalApp.isActive).toBe(true);
        expect(externalApp.expiryDate).toBe(null);
    });

    it('should open modal for editing', function() {

        fixture.controller();
        var externalApp = _.first(c.externalApps);

        http.get.returnValue = {
            result: {
                viewData: {
                    then: function(cb) {
                        return cb(externalApp);
                    }
                }
            }
        };
        c.editExternalApp(externalApp.id);

        expect(http.get).toHaveBeenCalledWith('api/externalApplication/externalApplicationTokenEditView?id=' + externalApp.id);
        expect(modalService.openModal).toHaveBeenCalledWith(jasmine.objectContaining({
            id: 'ExternalApplicationEdit',
            controllerAs: 'vm',
            viewData: externalApp
        }));
    });

});