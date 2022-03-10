describe('inprotech.configuration.general.jurisdictions.ValidNumbersController', function () {
    'use strict';

    var controller, kendoGridBuilder, modalService;

    beforeEach(function () {
        module('inprotech.configuration.general.jurisdictions');
        module(function ($provide) {
            var $injector = angular.injector(['inprotech.mocks.configuration.general.jurisdictions', 'inprotech.mocks.components.grid', 'inprotech.mocks']);
            $provide.value('jurisdictionValidNumbersService', $injector.get('JurisdictionMaintenanceServiceMock'));
            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);
            test.mock('dateService');
            modalService = $injector.get('modalServiceMock');
            $provide.value('modalService', modalService);
        });
    });

    beforeEach(inject(function ($controller) {
        controller = function (dependencies) {
            dependencies = angular.extend({
                $scope: {
                    parentId: 'ZZ'
                }
            }, dependencies);

            var c = $controller('ValidNumbersController', dependencies, {
                topic: {}
            });
            c.$onInit();
            return c;
        };
    }));

    it('should initialise the page, and have the correct grid columns', function () {
        var c = controller();
        expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
        expect(c.gridOptions).toBeDefined();
        expect(_.pluck(c.gridOptions.columns, 'field')).toEqual(['propertyTypeName', 'numberTypeName', 'caseTypeName', 'caseCategoryName', 'subTypeName', 'validFrom', 'pattern', 'warningFlag', 'displayMessage']);
    });

    describe('add number pattern', function () {
        it('should call modalService with add mode', function () {
            var c = controller();

            c.onAddClick();

            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'ValidNumbersMaintenance',
                    mode: 'add'
                })));
        });
    });

    describe('edit number pattern', function () {
        it('should call modalService with edit mode', function () {
            var c = controller();

            c.onEditClick();

            expect(modalService.openModal).toHaveBeenCalledWith(
                jasmine.objectContaining(_.extend({
                    id: 'ValidNumbersMaintenance',
                    mode: 'edit'
                })));
        });
    });
    describe('number pattern topic', function () {
        it('should be dirty when a record is added in the grid', function () {
            var c = controller();
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            isAdded: false
                        }, {
                            id: 2,
                            isAdded: true
                        }]
                    }
                }
            };
            var isDirty = c.topic.isDirty();
            expect(isDirty).toBe(true);
        });
        it('should get form data for added items only', function () {
            var c = controller();
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            isAdded: false
                        }, {
                            id: 2,
                            isAdded: true
                        }]
                    }
                }
            };

            var data = c.topic.getFormData().validNumbersDelta.added;
            expect(data.length).toBe(1);
            expect(_.first(data).countryCode).toBe('ZZ');
            expect(_.first(data).id).toBe(2);
        });
        it('should be dirty when a record is edited in the grid', function () {
            var c = controller();
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            isEdited: false
                        }, {
                            id: 2,
                            isEdited: true
                        }]
                    }
                }
            };

            var isDirty = c.topic.isDirty();
            expect(isDirty).toBe(true);
        });
        it('should get form data for edited items only', function () {
            var c = controller();
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            isEdited: false
                        }, {
                            id: 2,
                            isEdited: true
                        }]
                    }
                }
            };

            var data = c.topic.getFormData().validNumbersDelta.updated;
            expect(data.length).toBe(1);
            expect(_.first(data).countryCode).toBe('ZZ');
            expect(_.first(data).id).toBe(2);
        });
        it('should be dirty when a record is deleted in the grid', function () {
            var c = controller();
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            deleted: false
                        }, {
                            id: 2,
                            deleted: true
                        }]
                    }
                }
            };

            var isDirty = c.topic.isDirty();
            expect(isDirty).toBe(true);
        });
        it('should get form data for deleted items only', function () {
            var c = controller();
            c.gridOptions = {
                dataSource: {
                    data: function () {
                        return [{
                            id: 1,
                            deleted: false
                        }, {
                            id: 2,
                            deleted: true
                        }]
                    }
                }
            };

            var data = c.topic.getFormData().validNumbersDelta.deleted;
            expect(data.length).toBe(1);
            expect(_.first(data).countryCode).toBe('ZZ');
            expect(_.first(data).id).toBe(2);
        });
    });
});
