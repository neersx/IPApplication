describe('EntryStepsMaintenanceController', function() {

    'use strict';

    var controller, workflowsEntryControlService, notificationService, stepService, scope, maintModalService;


    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');

        module(function() {
            test.mock('$uibModalInstance', 'ModalInstanceMock');
            workflowsEntryControlService = test.mock('workflowsEntryControlService');
            maintModalService = test.mock('maintenanceModalService');
            notificationService = test.mock('notificationService');
            stepService = test.mock('workflowsEntryControlStepsService');
        });

        inject(function($rootScope, $controller) {
            controller = function(options) {
                scope = $rootScope.$new();
                var ctrl = $controller('EntryStepsMaintenanceController', {
                    $scope: scope,
                    options: _.extend({
                        addItem: jasmine.createSpy,
                        editItem: jasmine.createSpy
                    }, options)
                });

                return ctrl;
            };
        });
    });

    describe('initialise', function() {
        it('should initialise vm', function() {
            var ctrl = controller({
                criteriaId: 'criteriaId',
                entryId: 'entryId',
                entryDescription: 'entryDescription'
            });

            expect(ctrl).toEqual(jasmine.objectContaining({
                criteriaId: 'criteriaId',
                entryId: 'entryId',
                entryDescription: 'entryDescription',
                apply: jasmine.any(Function),
                isApplyEnabled: jasmine.any(Function)
            }));
        });

        it('initialises title for add mode', function() {
            var ctrl = controller({
                mode: 'add'
            });
            expect(ctrl.title).toBe('.addTitle');
        });

        it('initialises title for edit mode', function() {
            var ctrl = controller({
                mode: 'edit'
            });
            expect(ctrl.title).toBe('.editTitle');
        });
    });

    describe('isApplyEnabled', function() {
        it('calls isApplyEnabled from Service', function() {
            var ctrl = controller();
            ctrl.form = {
                $pristine: true
            };

            workflowsEntryControlService.isApplyEnabled = jasmine.createSpy().and.returnValue('aaa');

            var r = ctrl.isApplyEnabled();

            expect(r).toEqual('aaa');
            expect(workflowsEntryControlService.isApplyEnabled).toHaveBeenCalledWith(ctrl.form);
        });
    });

    describe('apply', function() {
        var data;
        beforeEach(function(){
            data = {
                step: {
                    id: 100
                },
                title: 'step'
            };
        });

        it('checks if form is valid', function() {
            var ctrl = controller();
            ctrl.form = {
                $validate: _.constant(false)
            };

            ctrl.apply();

            expect(workflowsEntryControlService.setEditedAddedFlags).not.toHaveBeenCalled();
            expect(maintModalService().applyChanges).not.toHaveBeenCalled();
        });

        it('sets flags and calls apply method for add', function() {
            var options = {
                mode: 'add',
                isAddAnother: true
            };

            var ctrl = controller(options);
            ctrl.formData = data;
            ctrl.form = {
                $validate: _.constant(true)
            };

            ctrl.apply();

            expect(workflowsEntryControlService.setEditedAddedFlags).toHaveBeenCalledWith(jasmine.objectContaining(data), false)

            expect(maintModalService().applyChanges).toHaveBeenCalledWith(jasmine.objectContaining(data), jasmine.objectContaining(options), false, true, undefined);
        });
        
        it('sets flags and calls apply method for edit', function(){
            var options = {
                mode: 'edit',
                isAddAnother: false
            };

            var ctrl = controller(options);
            ctrl.formData = data;
            ctrl.form = {
                $validate: _.constant(true)
            };

            ctrl.apply();

            expect(workflowsEntryControlService.setEditedAddedFlags).toHaveBeenCalledWith(jasmine.objectContaining(data), true)

            expect(maintModalService().applyChanges).toHaveBeenCalledWith(jasmine.objectContaining(data), jasmine.objectContaining(options), true, false, undefined);
        });

        it('apply notifies error for duplication, if the record is duplicated', function() {
            stepService.areStepsSame = jasmine.createSpy().and.returnValue(true);

            var dataItem = {
                step: {
                    type: 100
                }
            };
            var otherItem = {
                step: {
                    type: 100
                }
            };
            var formData = angular.copy(dataItem);
            formData.isEdited = true;

            var c = controller({
                all: [dataItem, otherItem],
                dataItem: formData
            });

            c.formData = formData;
            c.form = {
                $validate: _.constant(true),
                $dirty: true
            };
            c.apply();

            expect(notificationService.alert).toHaveBeenCalled();
        });
    });

    describe('on navigate', function() {
        it('navigates if the form is pristine', function() {
            var ctrl = controller({
                mode: 'edit',
                dataItem: 'dataItem'
            });
            ctrl.form = {
                $pristine: true,
                $validate: jasmine.createSpy().and.returnValue(false)
            };

            var result = ctrl.onNavigate();
            expect(result).toBe(true);
            expect(ctrl.form.$validate).not.toHaveBeenCalled();
        });

        it('applies changes automatically', function() {
            var ctrl = controller({
                mode: 'edit',
                dataItem: 'dataItem',
                apply: jasmine.createSpy()
            });
            ctrl.form = {
                $pristine: false,
                $validate: jasmine.createSpy().and.returnValue(false)
            };

            var result = ctrl.onNavigate();
            expect(result).toBe(false);
            expect(ctrl.form.$validate).toHaveBeenCalled();
        });
    });
});