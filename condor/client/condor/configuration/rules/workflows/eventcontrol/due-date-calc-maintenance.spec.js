describe('DueDateCalcMaintenanceController', function() {
    'use strict';

    var controller, modalInstance, notificationService, workflowsEventControlService, scope, maintModalService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');

        module(function() {
            modalInstance = test.mock('$uibModalInstance', 'ModalInstanceMock');
            notificationService = test.mock('notificationService');
            workflowsEventControlService = test.mock('workflowsEventControlService');
            maintModalService = test.mock('maintenanceModalService');
        });

        inject(function($controller, $rootScope) {
            scope = $rootScope.$new();
            scope.$emit = jasmine.createSpy();
            controller = function(options) {
                var ctrl = $controller('DueDateCalcMaintenanceController', {
                    $scope: scope,
                    options: _.extend({}, options)
                });

                return ctrl;
            };
        });
    });

    describe('initialise', function() {
        it('should initialise vm', function() {
            workflowsEventControlService.periodTypes = 'periodTypes';
            workflowsEventControlService.relativeCycles = 'relativeCycles';
            workflowsEventControlService.nonWorkDayOptions = 'nonWorkDay';

            var ctrl = controller({
                criteriaId: 'criteriaId',
                eventId: 'eventId',
                eventDescription: 'eventDescription',
                adjustByOptions: 'adjustByOptions',
                isCyclic: true,
                allowDueDateCalcJurisdiction: true,
                formData: {
                    cycle: null
                }
            });

            expect(ctrl).toEqual(jasmine.objectContaining({
                criteriaId: 'criteriaId',
                eventId: 'eventId',
                eventDescription: 'eventDescription',
                adjustByOptions: 'adjustByOptions',
                periodTypes: 'periodTypes',
                relativeCycles: 'relativeCycles',
                nonWorkDayOptions: 'nonWorkDay',
                isCycleDisabled: false,
                isJurisdictionDisabled: false,
                formData: {
                    fromTo: 1,
                    operator: 'A',
                    reminderOption: 'standard',
                    cycle: 1
                },
                eventPicklistScope: {
                    criteriaId: 'criteriaId',
                    filterByCriteria: true
                },
                apply: jasmine.any(Function),
                isApplyEnabled: jasmine.any(Function),
                onFromEventChange: jasmine.any(Function),
                dismiss: jasmine.any(Function),
                hasUnsavedChanges: jasmine.any(Function)

            }));
        });

        it('initialises picklistScope', function() {
            controller({
                criteriaId: 'criteriaId',
                eventPicklistScope: {
                    filterByCriteria: true
                }
            });

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
                    description: 'banana',
                    operator: 'B',
                    cycle: 2,
                    relativeCycle: 0
                }
            });

            expect(ctrl.formData).toEqual({
                fromTo: 1,
                operator: 'B',
                reminderOption: 'standard',
                description: 'banana',
                cycle: 2, 
                relativeCycle: 0
            });
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

    describe('apply', function() {
        var duplicateCheckFields = ['cycle', 'jurisdiction', 'fromEvent', 'relativeCycle', 'period'];
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

        it('checks duplicates in all data except for this dataItem', function() {
            var dataItem = {
                desciption: 'a'
            };
            var otherItem = {
                description: 'b'
            };
            var formData = {
                description: 'abc',
                isAdded: true
            };

            var ctrl = controller({
                allItems: [dataItem, otherItem],
                dataItem: dataItem,
                isAddAnother: false
            });
            ctrl.form = {
                $validate: _.constant(true),
                $dirty: true
            };
            ctrl.formData = formData;

            ctrl.apply();

            expect(workflowsEventControlService.isDuplicated).toHaveBeenCalledWith([otherItem], formData, duplicateCheckFields);
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

        it('sets flags and calls apply method for add', function () {
            var data = { description: 'added' };
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

        it('sets flags and calls apply method for edit', function () {
            var data = {description: 'edited'};
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

    describe('on from event change', function() {
        it('sets relative cycle to current cycle', function() {
            var ctrl = controller();
            ctrl.formData = {
                fromEvent: {
                    maxCycles: 1
                }
            };
            ctrl.onFromEventChange();
            expect(ctrl.formData.relativeCycle).toEqual(3);
        });

        it('sets relative cycle to cycle 1', function() {
            var ctrl = controller();
            ctrl.formData = {
                fromEvent: {
                    maxCycles: 2
                }
            };
            ctrl.onFromEventChange();
            expect(ctrl.formData.relativeCycle).toEqual(0);
        });
    });

    describe('set document generation compatibility', function() {
        it('allows exclusion of incompatible inprodoc only documents ', function() {
            var ctrl = controller();

            var r = ctrl.setDocumentGenerationCompatibility({});

            expect(r.options.legacy).toBe(true);
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

    describe('standing instruction warning', function() {
        it('adjustBy no warning if standing instruction selected', function(){
            var ctrl = controller({ standingInstructionCharacteristic: true });
            ctrl.formData = {adjustBy: '~0'};

            expect(ctrl.getAdjustByWarningText()).toEqual(null);
        });
        it('adjustBy warning if no standing instruction selected', function(){
            var ctrl = controller({ standingInstructionCharacteristic: false });
            ctrl.formData = {adjustBy: '~0'};

            expect(ctrl.getAdjustByWarningText()).not.toEqual(null);
        });

        it('period no warning if standing instruction selected', function(){
            var ctrl = controller({ standingInstructionCharacteristic: true });
            ctrl.formData = {period: {type: '1'}};

            expect(ctrl.getPeriodWarningText()).toEqual(null);
        });
        it('period warning if no standing instruction selected', function(){
            var ctrl = controller({ standingInstructionCharacteristic: false });
            ctrl.formData = {period: {type: '1' }};

            expect(ctrl.getPeriodWarningText()).not.toEqual(null);
        });

        it('ToCycle no warning if less than MaxCycles', function(){
            var ctrl = controller({ maxCycles: 2 });
            ctrl.formData = {cycle: 2};

            expect(ctrl.getToCycleWarningText()).toEqual(null);
        });
        it('ToCycle warning if greater than MaxCycles', function(){
            var ctrl = controller({ maxCycles: 2 });
            ctrl.formData = {cycle: 3};

            expect(ctrl.getToCycleWarningText()).not.toEqual(null);
        });
    });
});