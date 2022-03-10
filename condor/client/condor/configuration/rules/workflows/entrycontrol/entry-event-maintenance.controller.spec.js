describe('EntryEventMaintenanceController', function() {
    'use strict';

    var controller, notificationService, workflowsEntryControlService, scope, maintModalService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');

        module(function() {
            test.mock('$uibModalInstance', 'ModalInstanceMock');
            notificationService = test.mock('notificationService');
            workflowsEntryControlService = test.mock('workflowsEntryControlService');
            maintModalService = test.mock('maintenanceModalService');
        });

        inject(function($rootScope, $controller) {
            controller = function(options) {
                scope = $rootScope.$new();
                var ctrl = $controller('EntryEventMaintenanceController', {
                    $scope: scope,
                    options: _.extend({dataItem: {
                        previousEventId: 1
                    }}, options)
                });

                return ctrl;
            };
        });
    });

    describe('initialise', function() {
        it('should initialise vm', function() {
            workflowsEntryControlService.periodTypes = 'periodTypes';
            workflowsEntryControlService.relativeCycles = 'relativeCycles';
            workflowsEntryControlService.nonWorkDayOptions = 'nonWorkDay';

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
        var data = {
            entryEvent: {
                key: 100
            },
            eventDate: 1
        };
        var duplicateCheckFields = ['entryEvent'];
        it('checks if form is valid', function() {
            var ctrl = controller();
            ctrl.form = {
                $validate: _.constant(false),
                $dirty: true
            };

            ctrl.apply();

            expect(workflowsEntryControlService.setEditedAddedFlags).not.toHaveBeenCalled();
            expect(maintModalService().applyChanges).not.toHaveBeenCalled();
        });

        it('shows error when attribute is not selected', function() {
            var ctrl = controller();
            ctrl.formData = {};
            ctrl.form = {
                $validate: _.constant(true),
                $dirty: true
            };

            ctrl.apply();

            expect(notificationService.alert).toHaveBeenCalled();
        });

        it('checks duplicates in all data except for this dataItem', function() {
            var dataItem = {
                entryEvent: {
                    key: 100
                }
            };
            var otherItem = {
                entryEvent: {
                    key: 101
                }
            };
            var formData = {
                entryEvent: {
                    key: 100
                },
                eventDate: 0,
                isAdded: true
            };

            var ctrl = controller({
                isAddAnother: false,
                all: [dataItem, otherItem],
                dataItem: dataItem
            });

            ctrl.form = {
                $validate: _.constant(true),
                $dirty: true
            };

            ctrl.formData = formData;

            ctrl.apply();

            expect(workflowsEntryControlService.isDuplicated).toHaveBeenCalledWith([otherItem], formData, duplicateCheckFields);
        });

        it('shows error when duplicated', function() {
            var ctrl = controller();
            workflowsEntryControlService.isDuplicated = _.constant(true);
            ctrl.formData = {
                eventDate: 0
            };
            ctrl.form = {
                $validate: _.constant(true),
                $dirty: true
            };

            ctrl.apply();

            expect(notificationService.alert).toHaveBeenCalled();
        });

        it('sets flags and calls apply method for add', function () {
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

        it('sets flags and calls apply method for edit', function () {
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

    describe('eventPicklistScope', function() {
        it('should extend query for event picklist', function() {
            var ctrl = controller({
                criteriaId: 'criteriaId'
            });
            ctrl.eventPicklistScope.filterByCriteria = true;
            ctrl.eventPicklistScope.picklistSearch = 'abc'

            var r = ctrl.eventPicklistScope.extendQuery({});

            expect(r).toEqual(jasmine.objectContaining({
                criteriaId: 'criteriaId',
                picklistSearch: 'abc'
            }));
        });
    });
});