describe('inprotech.configuration.general.jurisdictions.ClassesController', function() {
    'use strict';

    var controller, kendoGridBuilder, service, translate, promiseMock, picklistService, notificationService;
    var parentId = 'KR';

    beforeEach(function() {
        module('inprotech.configuration.general.jurisdictions');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks.core', 'inprotech.mocks.configuration.general.jurisdictions', 'inprotech.mocks.components.grid', 'inprotech.mocks.components.notification']);

            service = $injector.get('JurisdictionClassesServiceMock');
            $provide.value('jurisdictionClassesService', service);

            kendoGridBuilder = $injector.get('kendoGridBuilderMock');
            $provide.value('kendoGridBuilder', kendoGridBuilder);

            test.mock('dateService');
            promiseMock = $injector.get('promiseMock');

            notificationService = $injector.get('notificationServiceMock');
            $provide.value('notificationService', notificationService);

            picklistService = {
                openModal: promiseMock.createSpy()
            };
            $provide.value('picklistService', picklistService);
        });
    });

    beforeEach(inject(function($controller) {
        controller = function(dependencies) {
            dependencies = angular.extend({
                $scope: {
                    parentId: parentId
                },
                $translate: translate
            }, dependencies);

            if (!dependencies.activeTopic) {
                dependencies.activeTopic = null;
            }

            var c = $controller('ClassesController', dependencies, {
                topic: {
                    activeTopic: dependencies.activeTopic
                }
            });
            c.$onInit();
            return c;
        };
    }));

    describe('initialisation', function() {
        it('initialises classes grid with default columns', function() {
            var c = controller();
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
            expect(_.pluck(c.gridOptions.columns, 'field')).toEqual(['class', 'description', 'intClasses', 'subClass', 'effectiveDate', 'propertyType']);
            expect(c.gridOptions.detailTemplate.indexOf('data-has-int-classes="false"') == -1).toBe(true);
            expect(c.gridOptions.detailTemplate.indexOf('data-has-int-classes="true"') > -1).toBe(true);
            expect(c.topic.isActive).toBeUndefined();
        });
        it('should call search service correctly ', function() {
            var c = controller();
            c.gridOptions.getQueryParams = function() {
                return null;
            }
            var queryParams = {
                something: 'abc'
            };
            c.gridOptions.read(queryParams);
            expect(service.search).toHaveBeenCalledWith(queryParams, parentId);
        });

        it('should set isActive to true when activeTopic is classes', function() {
            var c = controller({
                activeTopic: 'classes'
            });
            expect(c.topic.isActive).toBe(true);
        });

        it('should set isActive to undefined when activeTopic is blank', function() {
            var c = controller({
                activeTopic: ''
            });
            expect(c.topic.isActive).toBeUndefined();
        });
        it('intitialises grid and detail template without IntClasses for "ZZZ" ', function() {
            var c = controller({
                $scope: {
                    parentId: 'ZZZ'
                }
            });
            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
            expect(_.pluck(c.gridOptions.columns, 'field')).toEqual(['class', 'description', 'subClass', 'effectiveDate', 'propertyType']);
            expect(c.gridOptions.detailTemplate.indexOf('data-has-int-classes="false"') > -1).toBe(true);
        });
    });
    describe('view item detail', function() {
        it('should be disabled when dataitem is dirty', function() {
            var c = controller();
            var dataItem = {
                isAdded: true
            };
            var r = c.shouldDisable(dataItem);

            expect(r).toBeTruthy();
        });
        it('should be enabled when dataitem is not dirty', function() {
            var c = controller();
            var dataItem = {
                isAdded: false,
                deleted: false,
                isEdited: false
            };
            var r = c.shouldDisable(dataItem);

            expect(r).toBeFalsy();
        });
        it('view item icon should be displayed if subclass is allowed', function() {
            var c = controller();
            var dataItem = {
                allowSubClass: 2
            };
            var r = c.allowSubClass(dataItem);

            expect(r).toBeTruthy();
        });
        it('view item icon should not be displayed if subclass is not configured for items', function() {
            var c = controller();
            var dataItem = {
                allowSubClass: 1
            };
            var r = c.allowSubClass(dataItem);

            expect(r).toBeFalsy();
        });
        it('view item icon tooltip should display data items count', function() {
            translate = {
                instant: jasmine.createSpy().and.returnValue('Items')
            };
            var c = controller();
            var dataItem = {
                itemsCount: 4
            };

            var r = c.itemMaintenanceToolTip(dataItem);
            expect(r).toBe('Items (4)');
        });
        it('open view item maintenance modal and show confirmation when grid has changes', function() {
            translate = {
                instant: jasmine.createSpy().and.returnValue('Items for Class 02')
            };

            var c = controller();
            c.gridOptions.dataSource.data = function() {
                return [{
                    id: 1,
                    isAdded: true
                }, {
                    id: 2
                }];
            };

            c.onViewItemClick({
                class: '02',
                subClass: 'A',
                propertyTypeCode: 'T'
            });

            expect(picklistService.openModal).toHaveBeenCalledWith(jasmine.any(Object), jasmine.objectContaining({
                type: 'classItems',
                canMaintain: true,
                canAddAnother: true,
                displayName: 'Items for Class 02',
                appendPicklistLabel: false,
                extendQuery: jasmine.any(Function),
                initialViewData: jasmine.objectContaining({
                    class: '02',
                    subClass: 'A',
                    countryCode: 'KR',
                    propertyType: 'T'
                })
            }));
            expect(notificationService.confirm).toHaveBeenCalled();
        });
        it('open view item maintenance modal and refresh the grid doesnot have any changes', function() {
            translate = {
                instant: jasmine.createSpy().and.returnValue('Items for Class 02')
            };

            var c = controller();
            c.gridOptions.dataSource.data = function() {
                return [{
                    id: 1
                }, {
                    id: 2
                }];
            };

            c.onViewItemClick({
                class: '02',
                subClass: 'A',
                propertyTypeCode: 'T'
            });

            expect(notificationService.confirm).not.toHaveBeenCalled();
            expect(c.gridOptions.search).toHaveBeenCalled();
        });
    });
});