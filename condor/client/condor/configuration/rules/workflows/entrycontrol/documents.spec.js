describe('inprotech.configuration.rules.workflows.ipWorkflowsEntryControlDocuments', function() {
    'use strict';

    var controller, kendoGridBuilder, service, viewData;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks', 'inprotech.mocks.components.grid', 'inprotech.mocks.configuration.rules.workflows']);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            service = $injector.get('workflowsEntryControlServiceMock');
            $provide.value('workflowsEntryControlService', service);
        });
    });

    beforeEach(inject(function($rootScope, $componentController) {
        controller = function() {
            var scope = $rootScope.$new();
            viewData = {
                canEdit: true,
                entryId: 1,
                criteriaId: 2
            };
            var topic = {
                params: {
                    viewData: viewData
                }
            };

            var c = $componentController('ipWorkflowsEntryControlDocuments', {
                $scope: scope
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
            expect(c.canEdit).toEqual(true);
            expect(c.gridOptions).toBeDefined();
            expect(c.onAddClick).toBeDefined();
            expect(c.checkDuplicate).toBeDefined();
            expect(c.onDocumentChanged).toBeDefined();

            expect(c.topic.getFormData).toBeDefined();
            expect(c.topic.hasError).toBeDefined();
            expect(c.topic.isDirty).toBeDefined();
            expect(c.topic.validate).toBeDefined();
            expect(c.topic.initialised).toEqual(true);
        });
    });

    describe('On Add Click', function() {
        it('should add an item to the end of the grid and default MustProduce to false', function() {
            var c = controller();
            var totalSpy = jasmine.createSpy().and.returnValue(99);
            c.gridOptions.dataSource = {
                total: totalSpy
            };
            c.onAddClick();
            expect(c.gridOptions.insertRow).toHaveBeenCalledWith(99, jasmine.objectContaining({
                added: true,
                mustProduce: false
            }));
        });

    });

    describe('topic state methods', function() {
        it('should return form data', function() {
            var c = controller();
            var data = [{
                document: {
                    key: 1
                },
                mustProduce: false,
                previousDocumentId: 1,
                isEdited: true
            }, {
                document: {
                    key: 2
                },
                mustProduce: false,
                previousDocumentId: 2,
                isEdited: true,
                deleted: true
            }, {
                document: {
                    key: 3
                },
                mustProduce: true,
                previousDocumentId: 3,
                isEdited: true,
                added: true
            }];
            var delta = {
                added: [{
                    documentId: 3,
                    mustProduce: true,
                    previousDocumentId: 3
                }],
                deleted: [{
                    documentId: 2,
                    mustProduce: false,
                    previousDocumentId: 2
                }],
                updated: [{
                    documentId: 1,
                    mustProduce: false,
                    previousDocumentId: 1
                }]
            };
            c.gridOptions.dataSource = {
                data: function() {
                    return data;
                }
            };

            var result = c.topic.getFormData();

            expect(result).toEqual({
                DocumentsDelta: delta
            });
        });

        it('should indicate errors on the form', function() {
            var c = controller();
            c.form = {
                '$invalid': true
            };
            expect(c.topic.hasError()).toBe(true);
            c.form.$invalid = false;
            expect(c.topic.hasError()).toBe(false);
        });

        it('should indicate changes on the form', function() {
            var c = controller();
            var data = {
                added: true,
                mustProduce: false
            }
            c.gridOptions.dataSource = {
                data: function() {
                    return {
                        data: data
                    }
                }
            };

            c.form = {
                '$dirty': true
            };
            expect(c.topic.isDirty()).toBe(true);

            c.form.$dirty = false;
            expect(c.topic.isDirty()).toBe(true);

            data.added = false;
            expect(c.topic.isDirty()).toBe(false);
        });
    });

    describe('on row edit', function() {
        var rowForm;
        beforeEach(function() {
            rowForm = {
                document: {
                    '$setValidity': jasmine.createSpy()
                }
            };
        });

        it('marks rows as isEdited', function() {
            var c = controller();

            var item = {};

            c.gridOptions.dataSource.data = jasmine.createSpy().and.returnValue([item]);

            c.onDocumentChanged(item, rowForm);
            expect(item.isEdited).toBe(true);
        });

        it('checks for duplicate events', function() {
            var c = controller();
            var item = {
                'b': 'b'
            };
            var allItems = {
                'b': 'b'
            };
            c.gridOptions.dataSource.data = jasmine.createSpy().and.returnValue(allItems);

            service.isDuplicated = jasmine.createSpy().and.returnValue(true);

            c.onDocumentChanged(item, rowForm);

            expect(service.isDuplicated).toHaveBeenCalledWith(jasmine.anything(), item, ['document']);
            expect(rowForm.document.$setValidity).toHaveBeenCalledWith('duplicate', false);
        });


    });
});