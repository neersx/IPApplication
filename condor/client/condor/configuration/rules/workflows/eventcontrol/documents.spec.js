describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlDocuments', function() {
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

    beforeEach(inject(function($rootScope, $componentController) {
        controller = function() {
            var scope = $rootScope.$new();
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
            var c = $componentController('ipWorkflowsEventControlDocuments', {
                $scope: scope,
                kendoGridBuilder: kendoGridBuilder,
                workflowsEventControlService: service
            }, {
                topic: topic
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialise controller', function() {
        it('should initialise variables correctly', function() {
            var c = controller();

            expect(c.canEdit).toBe(true);
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        });

        it('should read grid data from sevice', function() {
            var c = controller();

            c.gridOptions.read();
            expect(service.getDocuments).toHaveBeenCalledWith(-111, -222);
        });
    });

    it('should be dirty if grid dirty', function() {
        var c = controller();
        kendoGridService.isGridDirty.returnValue = true;
        expect(c.topic.isDirty()).toBe(true);
    });

    describe('get form data should call mapGridDelta', function() {
        var dataItem, expectedSaveModel, ctrl;
        beforeEach(function() {
            dataItem = {
                "sequence": 1,
                "document": {
                    "key": -15872,
                    "code": "US SB0001",
                    "value": "Declaration for Utility or Design Patent Application - Fillable Form"
                },
                "startBefore": {
                    "type": "W",
                    "value": 3
                },
                "stopTime": {
                    "type": "M",
                    "value": 9
                },
                "maxDocuments": 1,
                "chargeType": {
                    "key": 99998,
                    "value": "Renewal Extension"
                },
                "isPayFee": true,
                "isRaiseCharge": false,
                "isEstimate": true,
                "isDirectPay": false,
                "isCheckCycleForSubstitute": true,
                "inherited": true
            };

            expectedSaveModel = {
                sequence: 1,
                documentId: -15872,
                maxDocuments: 1,
                chargeType: 99998,
                isPayFee: true,
                isRaiseCharge: false,
                isEstimate: true,
                isDirectPay: false,
                isCheckCycleForSubstitute: true
            }

            ctrl = controller();
            dataItem.isAdded = true;

            ctrl.gridOptions = {
                dataSource: {}
            };
        });

        it('should not return null for schedule when produce is as schedule', function() {
            dataItem.produce = 'asScheduled';

            _.extend(expectedSaveModel, {
                produceWhen: 'asScheduled',
                startBeforeTime: 3,
                startBeforePeriod: 'W',
                repeatEveryTime: 0,
                repeatEveryPeriod: 'W',
                stopTimePeriod: 'M',
                stopTime: 9
            });


            ctrl.gridOptions.dataSource.data = _.constant([dataItem]);

            ctrl.topic.getFormData();

            expect(service.mapGridDelta).toHaveBeenCalledWith([dataItem], jasmine.any(Function))
            var mapFunc = service.mapGridDelta.calls.first().args[1];
            expect(mapFunc(dataItem)).toEqual(jasmine.objectContaining(expectedSaveModel));
        });

        it('should return null for schedule when produce is not as schedule', function() {
            dataItem.produce = 'eventOccurs';
            _.extend(expectedSaveModel, {
                produceWhen: 'eventOccurs',
                startBeforeTime: null,
                startBeforePeriod: null,
                repeatEveryTime: null,
                repeatEveryPeriod: null,
                stopTimePeriod: null,
                stopTime: null
            });

            ctrl.gridOptions.dataSource.data = _.constant([dataItem]);

            ctrl.topic.getFormData();

            expect(service.mapGridDelta).toHaveBeenCalledWith([dataItem], jasmine.any(Function))
            var mapFunc = service.mapGridDelta.calls.first().args[1];
            expect(mapFunc(dataItem)).toEqual(jasmine.objectContaining(expectedSaveModel));
        });
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
                    id: 'DocumentsMaintenance',
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
                    id: 'DocumentsMaintenance',
                    mode: 'add',
                    dataItem: {}
                }, expectedOptions))
            );
        });
    });
});