describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlReminders', function() {
    'use strict';

    var controller, kendoGridBuilder, kendoGridService, service, modalService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            kendoGridBuilder = test.mock('kendoGridBuilder');
            kendoGridService = test.mock('kendoGridService');
            service = test.mock('workflowsEventControlService');
            modalService = test.mock('modalService');
        });
    });

    beforeEach(inject(function($componentController) {
        controller = function() {
            var topic = {
                params: {
                    viewData: {
                        criteriaId: -111,
                        eventId: -222,
                        canEdit: true,
                        overview: {
                            data: {
                                description: 'description'
                            }
                        }
                    }
                }
            };
            var c = $componentController('ipWorkflowsEventControlReminders', {
                $scope: {},
                kendoGridBuilder: kendoGridBuilder,
                workflowsEventControlService: service,
                kendoGridService: kendoGridService
            }, {
                topic: topic
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialise controller', function() {
        it('should initialise', function() {
            var c = controller();

            expect(c.canEdit).toBe(true);
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        });

        it('should read grid data from sevice', function() {
            var c = controller();

            c.gridOptions.read();
            expect(service.getReminders).toHaveBeenCalledWith(-111, -222);
        });
    });

    it('should be dirty if grid dirty', function() {
        var c = controller();
        kendoGridService.isGridDirty.returnValue = true;
        expect(c.topic.isDirty()).toBe(true);
    });

    it('get form data should call mapGridDelta', function() {
        var dataItem = {
            sequence: 1,
            standardMessage: 'standard message',
            alternateMessage: 'alternate message',
            useOnAndAfterDueDate: true,
            sendEmail: 'send email',
            emailSubject: 'email subject',
            startBefore: {
                type: 'W',
                value: 3
            },
            repeatEvery: null,
            stopTime: {
                type: null,
                value: null
            },
            sendToStaff: true,
            sendToSignatory: true,
            sendToCriticalList: false,
            name: {
                key: 10032,
                code: null,
                displayName: "Accounts Department"
            },
            nameTypes: [{
                key: '9',
                code: 'B',
                value: 'Author'
            }, {
                key: '23',
                code: 'PQ',
                value: 'Challenger (other side)'
            }],
            relationship: {
                key: 'CON',
                code: null,
                value: 'Contact'
            },
            isInherited: false
        };

        var expectedSaveModel = {
            sequence: 1,
            standardMessage: 'standard message',
            alternateMessage: 'alternate message',
            useOnAndAfterDueDate: true,
            sendEmail: 'send email',
            emailSubject: 'email subject',

            startBeforeTime: 3,
            startBeforePeriod: 'W',
            repeatEveryTime: 0,
            repeatEveryPeriod: 'W',

            stopTimePeriod: null,
            stopTime: null,
            sendToStaff: true,
            sendToSignatory: true,
            sendToCriticalList: false,
            name: 10032,
            relationship: 'CON',
            nameTypes: ['B', 'PQ']
        };

        var c = controller();
        dataItem.isAdded = true;

        c.gridOptions = {
            dataSource: {}
        };
        c.gridOptions.dataSource.data = _.constant([dataItem]);

        c.topic.getFormData();

        expect(service.mapGridDelta).toHaveBeenCalledWith([dataItem], jasmine.any(Function))
        var mapFunc = service.mapGridDelta.calls.first().args[1];
        expect(mapFunc(dataItem)).toEqual(jasmine.objectContaining(expectedSaveModel));
    });

    describe('showPeriodType', function() {
        var ctrl, result;

        beforeEach(function() {
            ctrl = controller();
        });

        it('should return empty string', function() {
            result = ctrl.showPeriodType(null);
            expect(result).toEqual('');
        });

        it('should call translate service and return both value and type', function() {
            var dataAttribute = {
                type: 'type',
                value: 'value'
            };
            service.translatePeriodType.and.returnValue(dataAttribute.type);

            result = ctrl.showPeriodType(dataAttribute);

            expect(result).toEqual('value type');
            expect(service.translatePeriodType).toHaveBeenCalledWith(dataAttribute.type);
        });

        it('should return type only', function() {
            var dataAttribute = {
                type: 'type',
                value: null
            }
            service.translatePeriodType.and.returnValue(dataAttribute.type);

            result = ctrl.showPeriodType(dataAttribute);

            expect(result).toEqual('type');
        });
    });

    describe('opens modal for maintenance', function() {
        var expectedOptions = {
            criteriaId: -111,
            eventId: -222,
            eventDescription: 'description',
            isAddAnother: false,
            addItem: jasmine.any(Function)
        };
        it('onEditClick', function() {
            var dataItem = {
                abc: 'abc'
            };
            var ctrl = controller();
            ctrl.onEditClick(dataItem);
            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'RemindersMaintenance',
                    mode: 'edit',
                    dataItem: dataItem
                }, expectedOptions))
            );
        });

        it('onAddClick', function() {
            var ctrl = controller();
            ctrl.onAddClick();

            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'RemindersMaintenance',
                    mode: 'add',
                    dataItem: {}
                }, expectedOptions))
            );
        });
    });
});
