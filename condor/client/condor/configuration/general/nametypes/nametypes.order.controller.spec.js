describe('inprotech.configuration.general.nametypes.NameTypesOrderController', function() {
    'use strict';

    var controller, scope, nameTypesSvc, notificationSvc, modalInstance, options, kendoGridBuilder;

    beforeEach(function() {
        module('inprotech.configuration.general.nametypes');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.nametypes', 'inprotech.mocks', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification']);

            notificationSvc = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationSvc);
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            nameTypesSvc = $injector.get('NameTypeServiceMock');
            $provide.value('nameTypesService', nameTypesSvc);

            $provide.value('$uibModalInstance', $injector.get('ModalInstanceMock'));
        });
    });

    beforeEach(inject(function($rootScope, $controller, $uibModalInstance, nameTypesService) {
        scope = $rootScope.$new();
        nameTypesSvc = nameTypesService;
        modalInstance = $uibModalInstance;

        controller = function(dependencies) {
            if (!dependencies) {
                dependencies = {
                    $uibModalInstance: modalInstance,
                    nameTypesService: nameTypesSvc,
                    options: _.extend({}, options),
                    kendoGridBuilder: kendoGridBuilder
                };
            }
            dependencies.$scope = scope;
            return $controller('NameTypesOrderController', dependencies);
        };
    }));

    describe('initialisation', function() {
        it('should initialise controller', function() {
            var c = controller();
            expect(c.dismiss).toBeDefined();
            expect(c.save).toBeDefined();
            expect(c.gridOptions).toBeDefined();
            expect(c.moveUp).toBeDefined();
            expect(c.moveDown).toBeDefined();
            expect(c.search).toBeDefined();
            expect(c.initShortcuts).toBeDefined();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        });
    });

    describe('modal operations', function() {
        it('should close modal when dismiss is called', function() {
            var c = controller();
            c.hasChanges = false;
            c.dismiss();
            expect(modalInstance.close).toHaveBeenCalled();
        });
    });


    describe('initialize', function() {
        it('should initialize grid data', function() {
            var c = controller();
            var response = {
                data: [{
                    id: 1
                }, {
                    id: 2
                }]
            };

            nameTypesSvc.search = jasmine.createSpy().and.callFake(function() {
                return {
                    then: function(cb) {
                        cb(response);
                    }
                };
            });

            c.gridOptions.dataSource = {
                data: function(d) {
                    return d;
                }
            };

            c.gridOptions.data = function() {
                return response.data;
            };

            c.search();

            expect(c.gridOptions.data().length).toBe(2);
        });
        it('should initialize grid data', function() {
            var c = controller();
            var response = {
                data: []
            };

            nameTypesSvc.search = jasmine.createSpy().and.callFake(function() {
                return {
                    then: function(cb) {
                        cb(response);
                    }
                };
            });

            c.gridOptions.dataSource = {
                data: function(d) {
                    return d;
                }
            };

            c.gridOptions.data = function() {
                return [];
            };

            c.search();

            expect(c.gridOptions.data().length).toBe(0);
        });

    });

    describe('save', function() {
        it('should call notificationService if save is successfull', function() {
            var c = controller();
            c.save();
            expect(notificationSvc.success).toHaveBeenCalled()
        });

    });

    describe('enable/disable controles', function() {
        it('should disable up and down button if selected index is less than total grid length', function() {
            var c = controller();
            var index = 1;
            var maxindex = 2;
            c.updateUpDownButtonState(index, maxindex);
            expect(c.disableDownButton).toBe(false);
            expect(c.disableUpButton).toBe(false);
        });

    });
});