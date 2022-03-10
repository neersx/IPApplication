describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlDuedatecalcComponent', function() {
    'use strict';

    var controller, kendoGridBuilder, kendoGridService, service, hotkeys, modalService, promiseMock, eventControlService, adjustByOptions;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            kendoGridBuilder = test.mock('kendoGridBuilder');
            kendoGridService = test.mock('kendoGridService');
            service = test.mock('workflowsDueDateCalcService');
            promiseMock = test.mock('promise');
            eventControlService = test.mock('workflowsEventControlService');
            modalService = test.mock('modalService');
        });

        inject(function($rootScope, $componentController) {
            controller = function(viewData) {
                hotkeys = test.getMock('hotkeysMock');
                adjustByOptions = {};
                service.initSettingsViewModel.and.callFake(function(m) {
                    return m;
                });
                var scope = $rootScope.$new();
                var topic = {
                    key: 'dueDateCalc',
                    title: 'Due Date Calculation',
                    template: '<ip-workflows-eventcontrol-duedatecalc data-topic="$topic" />',
                    params: {
                        viewData: _.extend({
                            criteriaId: -111,
                            eventId: -222,
                            canEdit: true,
                            dueDateCalcSettings: {
                                dateAdjustmentOptions: adjustByOptions
                            },
                            isInherited: true,
                            parent: {
                                dueDateCalcSettings: { imTheParent: 'parentDueDateCalcSettings' }
                            }
                        }, viewData)
                    }
                };
                var c = $componentController('ipWorkflowsEventControlDuedatecalc', {
                    $scope: scope,
                    hotkeys: hotkeys,
                    kendoGridBuilder: kendoGridBuilder,
                    workflowsDueDateCalcService: service,
                    modalService: modalService,
                    workflowsEventControlService: eventControlService
                }, {
                    topic: topic
                });
                c.$onInit();
                return c;
            };
        });
    });

    describe('initialise controller', function() {
        it('should initialise vm', function() {
            var c = controller();

            expect(c.criteriaId).toEqual(-111);
            expect(c.eventId).toEqual(-222);
            expect(c.canEdit).toEqual(true);
            expect(service.initSettingsViewModel).toHaveBeenCalled();
            expect(c.topic.initializeShortcuts).toBeDefined();
            expect(c.parentData.imTheParent).toEqual('parentDueDateCalcSettings');
        });
    });

    it('should turn off extend due date when saving due date', function() {
        var c = controller();
        c.settings = {
            isSaveDueDate: true,
            extendDueDate: true
        };

        c.updateSaveDueDate();

        expect(c.settings.isSaveDueDate).toEqual(true);
        expect(c.settings.extendDueDate).toEqual(false);
    });
    
    it('should turn off saving due date when extend due date', function() {
        var c = controller();
        c.settings = {
            isSaveDueDate: true,
            extendDueDate: true
        };

        c.updateExtendDueDate();

        expect(c.settings.isSaveDueDate).toEqual(false);
        expect(c.settings.extendDueDate).toEqual(true);
    });

    describe('isDirty', function() {
        var ctrl;
        beforeEach(function() {
            ctrl = controller();
            ctrl.form = {
                $dirty: false
            };
            kendoGridService.isGridDirty.returnValue = false;
        });

        it('returns false if not dirty', function() {
            expect(ctrl.topic.isDirty()).toBeFalsy();
        });

        it('returns true if form is dirty', function() {
            ctrl.form.$dirty = true;
            expect(ctrl.topic.isDirty()).toBe(true);
        });

        it('returns true if grid is dirty', function() {
            kendoGridService.isGridDirty.returnValue = true;
            expect(ctrl.topic.isDirty()).toBe(true);
        });
    });

    describe('showPeriod', function() {
        it('returns empty string for null period', function() {
            var ctrl = controller();

            var result = ctrl.showPeriod({});

            expect(result).toBe('');
        });

        it('returns value and translated type concatenated', function() {
            var ctrl = controller();
            eventControlService.translatePeriodType.returnValue = 'Days';

            var result = ctrl.showPeriod({
                period: {
                    value: 1,
                    type: 'D'
                }
            });

            expect(result).toBe('1 Days');

            result = ctrl.showPeriod({
                period: {
                    value: 0,
                    type: 'D'
                }
            });

            expect(result).toBe('0 Days');
        });

        it('returns only translated type if value is null', function() {
            var ctrl = controller();
            eventControlService.translatePeriodType.returnValue = 'Entered';

            var result = ctrl.showPeriod({
                period: {
                    value: null,
                    type: 'E'
                }
            });

            expect(result).toBe('Entered');
        });
    });

    describe('maintenance', function() {
        var ctrl, expectedOptions, newData, dataItem;
        beforeEach(function() {
            ctrl = controller({
                criteriaId: 99,
                eventId: -11,
                overview: {
                    data: {
                        description: 'banana',
                        maxCycles: 2
                    }
                },
                allowDueDateCalcJurisdiction: 'allowDueDateCalcJurisdiction',
                standingInstruction: {
                    requiredCharacteristic: 'something'
                }
            });
            ctrl.gridOptions = {
                dataSource: {
                    insert: jasmine.createSpy()
                }
            };
            ctrl.gridOptions.dataSource.data = _.constant([{
                description: 'banana'
            }]);

            expectedOptions = {
                criteriaId: 99,
                eventId: -11,
                eventDescription: 'banana',
                isCyclic: true,
                allItems: ctrl.gridOptions.dataSource.data(),
                allowDueDateCalcJurisdiction: 'allowDueDateCalcJurisdiction',
                adjustByOptions: adjustByOptions,
                isAddAnother: false,
                addItem: jasmine.any(Function)
            };

            dataItem = {
                description: 'dataItem'
            };
            newData = {
                description: 'newData'
            };
            modalService.openModal = promiseMock.createSpy(newData);
        });

        describe('onAddClick', function() {
            it('opens modal for maintenance', function() {
                ctrl.onAddClick();

                expect(modalService.openModal).toHaveBeenCalledWith(
                    jasmine.objectContaining(_.extend({
                        id: 'DueDateCalcMaintenance',
                        mode: 'add'
                    }, expectedOptions))
                );
            });
        });

        describe('onEditClick', function() {
            it('opens modal for maintenance', function() {
                ctrl.onEditClick(dataItem);

                expect(modalService.openModal).toHaveBeenCalledWith(
                    jasmine.objectContaining(_.extend({
                        id: 'DueDateCalcMaintenance',
                        mode: 'edit',
                        dataItem: dataItem
                    }, expectedOptions))
                );
            });
        });

        describe('prepare grid data for saving', function() {
            var dataItem, expectedSaveModel;
            beforeEach(function() {
                dataItem = {
                    sequence: 1,
                    fromEvent: {
                        key: 'k1'
                    },
                    fromTo: 'fromTo',
                    mustExist: 'mustExist',
                    operator: 'operator',
                    period: {
                        value: 'period',
                        type: 'periodType'
                    },
                    adjustBy: 'adjustBy',
                    nonWorkDay: 'nonWorkDay',
                    relativeCycle: 'relativeCycle',
                    cycle: 'cycle',
                    jurisdiction: {
                        key: 'k2'
                    },
                    document: {
                        key: 'k3'
                    },
                    reminderOption: 'reminderOption'
                };

                expectedSaveModel = {
                    sequence: 1,
                    fromEventId: 'k1',
                    fromTo: 'fromTo',
                    mustExist: 'mustExist',
                    operator: 'operator',
                    period: 'period',
                    periodType: 'periodType',
                    adjustBy: 'adjustBy',
                    nonWorkDay: 'nonWorkDay',
                    relativeCycle: 'relativeCycle',
                    cycle: 'cycle',
                    jurisdictionId: 'k2',
                    documentId: 'k3',
                    reminderOption: 'reminderOption'
                };
            });

            it('should convert due dates delta to save model', function() {
                var c = controller();
                dataItem.isAdded = true;

                c.gridOptions = {
                    dataSource: {}
                };
                c.gridOptions.dataSource.data = _.constant([dataItem]);

                c.topic.getFormData();

                expect(eventControlService.mapGridDelta).toHaveBeenCalledWith([dataItem], jasmine.any(Function))
                var mapFunc = eventControlService.mapGridDelta.calls.first().args[1];
                expect(mapFunc(dataItem)).toEqual(jasmine.objectContaining(expectedSaveModel));
            });
        });

        describe('jurisdiction column visibility', function() {
            it('jurisdiction should be visible', function() {
                var c = controller({
                    allowDueDateCalcJurisdiction: true
                });

                expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();

                var columns = kendoGridBuilder.buildOptions.calls.mostRecent().args[1].columns;
                expect(columns.length).toEqual(10);
                expect(columns[1].title).toMatch(/cycle/);
                expect(columns[2].title).toMatch(/jurisdiction/);
                expect(columns[3].title).toMatch(/operator/);

                c.topic.getFormData();
            });

            it('jurisdiction should be Invisible', function() {
                var c = controller({
                    allowDueDateCalcJurisdiction: false
                });

                expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();

                var columns = kendoGridBuilder.buildOptions.calls.mostRecent().args[1].columns;
                expect(columns.length).toEqual(9);
                expect(columns[1].title).toMatch(/cycle/);
                expect(columns[2].title).toMatch(/operator/);

                c.topic.getFormData();
            });
        });

        describe('isInherited method', function() {
            it('should return if parent is the same as child', function() {
                var c = controller();
                c.settings = {
                    dateToUse: 'a',
                    isSaveDueDate: 'b',
                    extendDueDate: 'c',
                    extendDueDateOptions: 'd',
                    recalcEventDate: 'e',
                    doNotCalculateDueDate: 'f'
                };
                c.parentData = _.clone(c.settings);

                expect(c.isInherited()).toEqual(true);

                c.settings.dateToUse = 'x';
                expect(c.isInherited()).toEqual(false);
                c.settings.dateToUse = 'a';

                c.settings.isSaveDueDate = 'x';
                expect(c.isInherited()).toEqual(false);
                c.settings.isSaveDueDate = 'b';

                c.settings.extendDueDate = 'x';
                expect(c.isInherited()).toEqual(false);
                c.settings.extendDueDate = 'c';

                c.settings.extendDueDateOptions = 'x';
                expect(c.isInherited()).toEqual(false);
                c.settings.extendDueDateOptions = 'd';

                c.settings.recalcEventDate = 'x';
                expect(c.isInherited()).toEqual(false);
                c.settings.recalcEventDate = 'e';
                
                c.settings.doNotCalculateDueDate = 'x';
                expect(c.isInherited()).toEqual(false);
                c.settings.doNotCalculateDueDate = 'f';

                expect(c.isInherited()).toEqual(true);
            });
        });
    });
});