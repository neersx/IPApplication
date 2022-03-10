describe('inprotech.configuration.rules.workflows.ipWorkflowsEntryControlSteps', function() {
    'use strict';

    var controller, kendoGridBuilder, service, modalService, promiseMock, $translate, notificationService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            kendoGridBuilder = test.mock('kendoGridBuilder');

            service = test.mock('workflowsEntryControlStepsService');

            promiseMock = test.mock('promise');

            notificationService = test.mock('notificationService');
        });
    });

    beforeEach(inject(function($rootScope, $componentController) {
        $translate = {
            instant: jasmine.createSpy().and.returnValue('translated text')
        }
        controller = function() {
            var scope = $rootScope.$new();
            var topic = {
                params: {
                    viewData: {
                        criteriaId: -111,
                        entryId: -222,
                        characteristics: {},
                        description: 'Entry',
                        canEdit: true
                    }
                }
            };
            modalService = {
                openModal: promiseMock.createSpy()
            };
            var controller = $componentController('ipWorkflowsEntryControlSteps', {
                $scope: scope,
                kendoGridBuilder: kendoGridBuilder,
                modalService: modalService,
                workflowsEntryControlStepsService: service,
                $translate: $translate,
                notificationService: notificationService
            }, {
                topic: topic
            });

            controller.$onInit();

            _.extend(controller.gridOptions, {
                dataSource: {}
            });

            return controller;
        };
    }));

    describe('initialise controller', function() {
        it('should initialise variables correctly', function() {
            var c = controller();

            expect(c.canEdit).toEqual(true);
            expect(c.topic.initialised).toEqual(true);

            expect(c.topic.hasError).toBeDefined();
            expect(c.topic.isDirty).toBeDefined();
            expect(c.topic.getFormData).toBeDefined();

            expect(c.gridOptions.actions.edit).toBeDefined();
        });
    });

    describe('grid', function() {
        it('reads data from step service', function() {
            var c = controller();

            c.gridOptions.read();
            expect(service.getSteps).toHaveBeenCalledWith(-111, -222);
        });
    });

    describe('state checks', function() {
        it('returns dirty from isDirty, if step is added', function() {
            var c = controller();
            c.gridOptions.dataSource.data = _.constant([{
                isAdded: true
            }]);
            var result = c.topic.isDirty();
            expect(result).toBeTruthy();
        });

        it('returns dirty from isDirty, if step is updated', function() {
            var c = controller();
            c.gridOptions.dataSource.data = _.constant([{
                isEdited: true
            }]);
            var result = c.topic.isDirty();
            expect(result).toBeTruthy();
        });

        it('returns dirty from isDirty, if step is updated', function() {
            var c = controller();
            c.gridOptions.dataSource.data = _.constant([{
                isEdited: true
            }]);
            var result = c.topic.isDirty();
            expect(result).toBeTruthy();
        });

        it('returns errorous if steps grid contains error', function() {
            var c = controller();
            c.gridOptions.dataSource.data = _.constant([{
                error: true,
                isAdded: true
            }]);

            var result = c.topic.hasError();
            expect(result).toBeTruthy();
        });

        it('sets error', function() {
            var c = controller();
            c.gridOptions.dataSource.data = _.constant([{
                id: 1
            }, {
                id: 2
            }]);

            var errors = [{
                id: 1,
                field: 'title',
                errorMessage: 'error1'
            }, {
                id: 2,
                field: 'categoryValue',
                errorMessage: 'error2'
            }]

            c.topic.setError(errors);

            var first = c.gridOptions.dataSource.data()[0];
            expect(first.error).toBeTruthy();
            expect(first.errorMessage).toBe('translated text');

            var second = c.gridOptions.dataSource.data()[1];
            expect(second.error).toBeTruthy();
            expect(second.errorMessage).toBe('translated text');
        });
    });

    describe('maintennace', function() {
        var c, expectedOptions, dataItem, newData;

        beforeEach(function() {
            c = controller();

            c.gridOptions.dataSource.data = _.constant([{
                title: 'Step1'
            }, {
                title: 'Step2'
            }]);

            dataItem = _.first(c.gridOptions.dataSource.data());

            expectedOptions = {
                criteriaId: -111,
                criteriaCharacteristics: {},
                entryId: -222,
                entryDescription: 'Entry',
                all: c.gridOptions.dataSource.data()
            };

            newData = {
                title: 'New Step'
            };
            modalService.openModal = promiseMock.createSpy(newData);
        });


        describe('OnEditClick', function() {
            it('displays step maintenance dialog', function() {
                c.onEditClick(dataItem);

                expect(modalService.openModal).toHaveBeenCalledWith(
                    jasmine.objectContaining(_.extend({
                        id: 'EntryStepsMaintenance',
                        mode: 'edit',
                        dataItem: dataItem
                    }, expectedOptions)));
            });

            it('applies updates to record', function() {
                c.onEditClick(dataItem);

                expect(dataItem.title).toEqual(newData.title);
            });
        });
    });

    describe('getFormData', function() {
        var c, data;

        beforeEach(function() {
            c = controller();
            data = [{
                id: 1,
                step: {
                    key: 'B',
                    type: 'B'
                },
                title: 'Step1',
                screenTip: 'tip1',
                isMandatory: false,
                categories: []
            }, {
                id: 2,
                step: {
                    key: 'A',
                    type: 'A'
                },
                title: 'Step2',
                screenTip: 'tip2',
                isMandatory: true,
                categories: [{
                    categoryCode: 'textType'
                }, {
                    categoryCode: 'nameType'
                }]
            }];

            c.gridOptions.dataSource.data = jasmine.createSpy().and.callFake(
                function(d) {
                    if (!d) {
                        return data;
                    }

                    return d;
                });
        });

        it('includes updated step records', function() {
            var dataRecord = _.first(data);
            _.extend(dataRecord, {
                isEdited: true
            });

            var updatedData = c.topic.getFormData();

            expect(updatedData.stepsDelta.added.length).toBe(0);
            expect(updatedData.stepsDelta.deleted.length).toBe(0);
            expect(updatedData.stepsDelta.updated).toBeDefined();

            var updatedRecord = _.first(updatedData.stepsDelta.updated);

            expect(updatedRecord.id).toBe(dataRecord.id);
            expect(updatedRecord.screenName).toBe(dataRecord.step.key);
            expect(updatedRecord.screenType).toBe(dataRecord.step.type);
            expect(updatedRecord.title).toBe(dataRecord.title);
            expect(updatedRecord.screenTip).toBe(dataRecord.screenTip);
            expect(updatedRecord.isMandatory).toBe(dataRecord.isMandatory);
        });

        it('includes added step records', function() {
            var dataRecord = angular.extend(data[1], {
                id: null,
                relativeId: 10
            });
            _.extend(dataRecord, {
                isAdded: true
            });

            var modifiedData = c.topic.getFormData();

            expect(modifiedData.stepsDelta.added).toBeDefined(0);
            expect(modifiedData.stepsDelta.deleted.length).toBe(0);
            expect(modifiedData.stepsDelta.updated.length).toBe(0);

            var addedRecord = _.first(modifiedData.stepsDelta.added);

            expect(addedRecord.newItemId).toBe('A');
            expect(addedRecord.relativeId).toBe(10);

            expect(addedRecord.screenName).toBe(dataRecord.step.key);
            expect(addedRecord.screenType).toBe(dataRecord.step.type);
            expect(addedRecord.title).toBe(dataRecord.title);
            expect(addedRecord.screenTip).toBe(dataRecord.screenTip);
            expect(addedRecord.isMandatory).toBe(dataRecord.isMandatory);
            expect(addedRecord.categories).toBeDefined();
            expect(addedRecord.categories[0].categoryCode).toBe(dataRecord.categories[0].categoryCode);
            expect(addedRecord.categories[1].categoryCode).toBe(dataRecord.categories[1].categoryCode);
        });

        it('throws error if more than expected new records are added', function() {
            _.each(_.range(65, 128), function() {
                data.push({
                    step: {},
                    isAdded: true
                });
            });

            expect(c.topic.getFormData).toThrow(new Error('Too many new steps added. Rectify and try again.'));
            expect(notificationService.alert).toHaveBeenCalled();
        });

        it('should set flag for reorder when dropped', function() {
            var c = controller();

            var args = {
                source: {},
                target: {},
                insertBefore: true
            };

            c.gridOptions.onDropCompleted(args);
            expect(args.source.moved).toBe(true);
        });

        it('includes moved records, sets relative step id', function() {
            var record1 = {
                id: 1,
                step: {}
            };

            var record2 = {
                id: 2,
                step: {},
                moved: true
            };

            var record3 = {
                id: null,
                step: {},
                isAdded: true
            };

            var record4 = {
                id: 3,
                step: {},
                moved: true
            };

            c.gridOptions.dataSource.data = _.constant([record1, record2, record3, record4]);

            spyOn(c.gridOptions, "getRelativeItemAbove").and.returnValues(record1,record1, record3);

            var updatedData = c.topic.getFormData();

            expect(updatedData.stepsDelta.added.length).toBe(1);
            expect(updatedData.stepsMoved.length).toBe(2);

            var movedRecord1 = updatedData.stepsMoved[0];
            expect(movedRecord1.id).toBe(data[1].stepId);
            expect(movedRecord1.prevStepIdentifier).toBe(data[0].id);

            var movedRecord2 = updatedData.stepsMoved[1];
            expect(movedRecord2.id).toBe(record4.stepId);
            expect(movedRecord2.prevStepIdentifier).toBe('A');
        });
    });
});
