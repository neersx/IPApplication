describe('DateComparisonMaintenanceController', function() {
    'use strict';

    var scope, controller, modalInstance, notificationService, workflowsEventControlService, dateHelperService, maintModalService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module('inprotech.core');

        module(function() {
            modalInstance = test.mock('$uibModalInstance', 'ModalInstanceMock');
            notificationService = test.mock('notificationService');
            workflowsEventControlService = test.mock('workflowsEventControlService');
            maintModalService = test.mock('maintenanceModalService');
        });

        inject(function($rootScope, $controller, dateHelper) {
            scope = $rootScope.$new();
            scope.$emit = jasmine.createSpy();
            dateHelperService = dateHelper;
            controller = function(options) {
                var ctrl = $controller('DateComparisonMaintenanceController', {
                    $scope: scope,
                    options: _.extend({}, options)
                });

                return ctrl;
            };
        });
    });

    describe('initialise', function() {
        it('should initialise vm', function() {
            workflowsEventControlService.relativeCycles = 'relativeCycles';
            workflowsEventControlService.operators = 'operators';

            var ctrl = controller({
                criteriaId: 'criteriaId',
                eventId: 'eventId',
                eventDescription: 'eventDescription',
                adjustByOptions: 'adjustByOptions',
                isCyclic: true,
                allowDateComparisonJurisdiction: true,
                requestReminderHelper: dateHelperService,
                isAddAnother: false,
                addItem: angular.noop
            });

            expect(ctrl).toEqual(jasmine.objectContaining({
                criteriaId: 'criteriaId',
                eventId: 'eventId',
                eventDescription: 'eventDescription',
                relativeCycles: 'relativeCycles',
                operators: 'operators',
                formData: {
                    eventADate: 'Event',
                    eventBDate: 'Event'
                },
                comparisonType: 'eventB',
                showEventB: true,
                showDate: false,
                showComparisonTypes: true,
                onEventAChange: jasmine.any(Function),
                onComparisonOperatorChanged: jasmine.any(Function),
                onEventBChange: jasmine.any(Function),
                onComparisonTypeChange: jasmine.any(Function),
                apply: jasmine.any(Function),
                isApplyEnabled: jasmine.any(Function),
                dismiss: jasmine.any(Function),
                hasUnsavedChanges: jasmine.any(Function),
                isAddAnother: false,
                addItem: jasmine.any(Function)
            }));

            expect(maintModalService).toHaveBeenCalledWith(scope, modalInstance, jasmine.any(Function));
            expect(workflowsEventControlService.initEventPicklistScope).toHaveBeenCalledWith({
                criteriaId: 'criteriaId',
                filterByCriteria: true
            });

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

        it('extends formData defaults to populate from dataItem', function() {
            var ctrl = controller({
                mode: 'edit',
                dataItem: {
                    a: 'a',
                    b: 'b'
                }
            });

            expect(ctrl.formData).toEqual({
                a: 'a',
                b: 'b',
                eventADate: 'Event',
                eventBDate: 'Event'
            });
        });

        describe('should get correct comparisonType', function() {
            it('should be date', function() {
                var ctrl = controller({
                    mode: 'edit',
                    dataItem: {
                        compareDate: '20170101',
                        compareSystemDate: false
                    }
                });

                expect(ctrl.comparisonType).toEqual('date');
            });

            it('should be systemDate', function() {
                var ctrl = controller({
                    mode: 'edit',
                    dataItem: {
                        compareDate: null,
                        compareSystemDate: true
                    }
                });
                expect(ctrl.comparisonType).toEqual('systemDate');
            });

            it('should be date', function() {
                var ctrl = controller({
                    mode: 'edit',
                    dataItem: {
                        compareDate: null,
                        compareSystemDate: false
                    }
                });
                expect(ctrl.comparisonType).toEqual('eventB');
            });
        });
    });

    describe('apply', function() {
        var duplicateCheckFields = ['eventA', 'eventADate', 'eventARelativeCycle', 'comparisonOperator', 'eventB', 'eventBDate', 'eventBRelativeCycle', 'compareRelationship', 'compareDate'];
        it('checks if form is valid', function() {
            var ctrl = controller();
            ctrl.form = {
                $validate: _.constant(false),
                $dirty: true
            };

            ctrl.apply();

            expect(workflowsEventControlService.setEditedAddedFlags).not.toHaveBeenCalled();
            expect(maintModalService().applyChanges).not.toHaveBeenCalled();
        });

        it('removes redundant comparison date in event mode', function() {
            var ctrl = controller();
            ctrl.showComparisonTypes = true;
            ctrl.comparisonType = 'eventB';
            ctrl.form = {
                $validate: _.constant(true),
                $dirty: true
            };
            ctrl.formData = {
                eventB: 'b',
                compareDate: 'toRemove'
            };
            ctrl.isAddAnother = false;

            ctrl.apply();

            var expectedData = {
                eventB: 'b',
                compareDate: null,
                compareSystemDate: false
            };

            expect(workflowsEventControlService.setEditedAddedFlags).toHaveBeenCalledWith(jasmine.objectContaining(expectedData), false)

            expect(maintModalService().applyChanges).toHaveBeenCalledWith(jasmine.objectContaining(expectedData), jasmine.any(Object), false, false, undefined);
        });

        it('removes redundant event comparison data in date mode', function() {
            var ctrl = controller();
            ctrl.showComparisonTypes = true;
            ctrl.comparisonType = 'date';
            ctrl.form = {
                $validate: _.constant(true),
                $dirty: true
            };
            ctrl.formData = {
                eventB: 'b',
                eventBDate: 'eventDateType',
                eventBRelativeCycle: 'eventRelativeCycle',
                compareRelationship: 'eventRelationship',
                compareDate: 'date'
            };
            ctrl.isAddAnother = false;
            ctrl.apply();

            var expectedData = {
                compareDate: 'date',
                eventB: null,
                eventBDate: null,
                eventBRelativeCycle: null,
                compareRelationship: null,
                compareSystemDate: false
            };

            expect(workflowsEventControlService.setEditedAddedFlags).toHaveBeenCalledWith(jasmine.objectContaining(expectedData), false)

            expect(maintModalService().applyChanges).toHaveBeenCalledWith(jasmine.objectContaining(expectedData), jasmine.any(Object), false, false, undefined);
        });

        it('removes redundant data in system date mode', function() {
            var ctrl = controller();
            ctrl.showComparisonTypes = true;
            ctrl.comparisonType = 'systemDate';
            ctrl.form = {
                $validate: _.constant(true),
                $dirty: true
            };
            ctrl.formData = {
                eventB: 'b',
                eventBDate: 'eventDateType',
                eventBRelativeCycle: 'eventRelativeCycle',
                compareRelationship: 'eventRelationship',
                compareDate: 'date'
            };
            ctrl.isAddAnother = false;

            ctrl.apply();

            var expectedData = {
                compareSystemDate: true,
                compareDate: null,
                eventB: null,
                eventBDate: null,
                eventBRelativeCycle: null,
                compareRelationship: null
            };

            expect(workflowsEventControlService.setEditedAddedFlags).toHaveBeenCalledWith(jasmine.objectContaining(expectedData), false)

            expect(maintModalService().applyChanges).toHaveBeenCalledWith(jasmine.objectContaining(expectedData), jasmine.any(Object), false, false, undefined);
        });

        it('removes redundant data when comparisonType is exist or non-exist', function() {
            var ctrl = controller();
            ctrl.showComparisonTypes = false;
            ctrl.comparisonType = 'systemDate';
            ctrl.form = {
                $validate: _.constant(true),
                $dirty: true
            };
            ctrl.formData = {
                eventB: 'b',
                eventBDate: 'eventDateType',
                eventBRelativeCycle: 'eventRelativeCycle',
                compareRelationship: 'eventRelationship',
                compareDate: 'date'
            };
            ctrl.isAddAnother = false;

            ctrl.apply();

            var expectedData = {
                compareSystemDate: null,
                compareDate: null,
                eventB: null,
                eventBDate: null,
                eventBRelativeCycle: null,
                compareRelationship: null
            };

            expect(workflowsEventControlService.setEditedAddedFlags).toHaveBeenCalledWith(jasmine.objectContaining(expectedData), false)

            expect(maintModalService().applyChanges).toHaveBeenCalledWith(jasmine.objectContaining(expectedData), jasmine.any(Object), false, false, undefined);
        });

        it('checks duplicates in all data except for this dataItem', function() {
            var dataItem = {
                a: 'abc'
            };
            var otherItem = {
                a: 'b'
            };
            var ctrl = controller({
                allItems: [dataItem, otherItem],
                dataItem: dataItem
            });
            ctrl.form = {
                $validate: _.constant(true),
                $dirty: true
            };
            ctrl.formData = {
                a: 'abc'
            };
            ctrl.isAddAnother = false;
            ctrl.addItem = jasmine.any(Function)

            ctrl.apply();

            expect(workflowsEventControlService.isDuplicated).toHaveBeenCalledWith([otherItem], jasmine.objectContaining({
                a: 'abc'
            }), duplicateCheckFields);
        });

        it('shows error when duplicated', function() {
            var ctrl = controller();
            workflowsEventControlService.isDuplicated = _.constant(true);
            ctrl.formData = {};
            ctrl.form = {
                $validate: _.constant(true),
                $dirty: true
            };

            ctrl.apply();

            expect(notificationService.alert).toHaveBeenCalled();
        });

        it('sets flags and calls apply method for add', function() {
            var data = {
                description: 'added'
            };
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

            expect(workflowsEventControlService.setEditedAddedFlags).toHaveBeenCalledWith(jasmine.objectContaining(data), false)

            expect(maintModalService().applyChanges).toHaveBeenCalledWith(jasmine.objectContaining(data), jasmine.objectContaining(options), false, true, undefined);
        });

        it('sets flags and calls apply method for edit', function() {
            var data = {
                description: 'edited'
            };
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

            expect(workflowsEventControlService.setEditedAddedFlags).toHaveBeenCalledWith(jasmine.objectContaining(data), true)

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

    describe('isApplyEnabled', function() {
        it('calls isApplyEnabled from Service', function() {
            var ctrl = controller();
            ctrl.form = {
                $pristine: true
            };

            workflowsEventControlService.isApplyEnabled = jasmine.createSpy().and.returnValue('aaa');

            var r = ctrl.isApplyEnabled();

            expect(r).toEqual('aaa');
            expect(workflowsEventControlService.isApplyEnabled).toHaveBeenCalledWith(ctrl.form);
        });
    });

    describe('eventPicklistScope', function() {
        it('should extend query for event picklist', function() {
            var ctrl = controller({
                criteriaId: 'criteriaId'
            });
            ctrl.eventPicklistScope.filterByCriteria = true;
            expect(workflowsEventControlService.initEventPicklistScope).toHaveBeenCalledWith({
                criteriaId: 'criteriaId',
                filterByCriteria: true
            });
        });
    });

    describe('on from event change', function() {
        it('sets relative cycle to current cycle', function() {
            var ctrl = controller();
            ctrl.formData = {
                eventA: {
                    maxCycles: 1
                },
                eventB: {
                    maxCycles: 1
                }
            };
            ctrl.onEventAChange();
            expect(ctrl.formData.eventARelativeCycle).toEqual(3);
            ctrl.onEventBChange();
            expect(ctrl.formData.eventBRelativeCycle).toEqual(3);
        });

        it('sets relative cycle to cycle 1', function() {
            var ctrl = controller();
            ctrl.formData = {
                eventA: {
                    maxCycles: 2
                },
                eventB: {
                    maxCycles: 9999
                }
            };
            ctrl.onEventAChange();
            expect(ctrl.formData.eventARelativeCycle).toEqual(0);
            ctrl.onEventBChange();
            expect(ctrl.formData.eventBRelativeCycle).toEqual(0);
        });
    });

    describe('comparison operator change', function() {
        it('hides comparison options when exists or not exists selected', function() {
            var ctrl = controller();

            ctrl.formData = {
                comparisonOperator: {
                    key: 'EX'
                }
            };
            ctrl.onComparisonOperatorChanged();
            expect(ctrl.showComparisonTypes).toBe(false);

            ctrl.formData = {
                comparisonOperator: {
                    key: 'NE'
                }
            };
            ctrl.onComparisonOperatorChanged();
            expect(ctrl.showComparisonTypes).toBe(false);
        });

        it('shows comparison options when comparison operator selected', function() {
            var ctrl = controller();

            ctrl.formData = {
                comparisonOperator: {
                    key: '>'
                }
            };
            ctrl.onComparisonOperatorChanged();
            expect(ctrl.showComparisonTypes).toBe(true);
        });
    });

    describe('comparison type change', function() {
        it('shows relevant option controls when comparison type changed', function() {
            var ctrl = controller();
            ctrl.showComparisonTypes = true;

            ctrl.comparisonType = 'eventB';
            ctrl.onComparisonTypeChange();
            expect(ctrl.showEventB).toBe(true);
            expect(ctrl.showDate).toBe(false);

            ctrl.comparisonType = 'date';
            ctrl.onComparisonTypeChange();
            expect(ctrl.showEventB).toBe(false);
            expect(ctrl.showDate).toBe(true);
        });

        it('hides compare options when nothing to compare', function() {
            var ctrl = controller();
            ctrl.showComparisonTypes = false;

            ctrl.comparisonType = 'eventB';
            ctrl.onComparisonTypeChange();
            expect(ctrl.showEventB).toBe(false);
            expect(ctrl.showDate).toBe(false);

            ctrl.comparisonType = 'date';
            ctrl.onComparisonTypeChange();
            expect(ctrl.showEventB).toBe(false);
            expect(ctrl.showDate).toBe(false);
        });
    });

    describe('dismiss', function() {
        it('calls uibModalInstance dismiss', function() {
            var ctrl = controller();
            ctrl.dismiss();
            expect(modalInstance.dismiss).toHaveBeenCalled();
        });
    });

    describe('hasUnsavedChanges', function() {
        it('returns true when form is dirty', function() {
            var ctrl = controller();
            ctrl.form = {
                $dirty: true
            };
            expect(ctrl.hasUnsavedChanges()).toBe(true);

            ctrl.form.$dirty = false;
            expect(ctrl.hasUnsavedChanges()).toBe(false);
        });
    });
});