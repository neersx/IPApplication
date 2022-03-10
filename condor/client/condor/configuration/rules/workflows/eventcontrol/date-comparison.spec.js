describe('inprotech.configuration.rules.workflows.ipWorkflowsEventControlDateComparison', function() {
    'use strict';

    var controller, kendoGridBuilder, kendoGridService, service, hotkeys, translate, dateService;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            kendoGridBuilder = test.mock('kendoGridBuilder');
            kendoGridService = test.mock('kendoGridService');
            service = test.mock('workflowsEventControlService');
            translate = test.mock('translate');
            dateService = test.mock('dateService');
        });
    });

    beforeEach(inject(function($rootScope, $componentController) {
        controller = function() {
            hotkeys = test.getMock('hotkeysMock');
            var scope = $rootScope.$new();
            var topic = {
                params: {
                    viewData: {
                        criteriaId: -111,
                        eventId: -222,
                        canEdit: true,
                        datesLogicComparisonType: 'Any',
                        isInherited: true,
                        parent:{ datesLogicComparisonType: 'abc'}
                    }
                }
            };
            var c = $componentController('ipWorkflowsEventControlDateComparison', {
                $scope: scope,
                kendoGridBuilder: kendoGridBuilder,
                workflowsEventControlService: service,
                hotkeys: hotkeys,
                $translate: translate,
                dateService: dateService
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

            expect(c.criteriaId).toEqual(-111);
            expect(c.eventId).toEqual(-222);
            expect(c.canEdit).toEqual(true);
            expect(c.formData.datesLogicComparisonType).toEqual('Any');
            expect(c.comparisonOptionsDisabled).toBeDefined();
            expect(c.topic.isDirty).toBeDefined();
            expect(c.topic.getFormData).toBeDefined();
            expect(c.topic.initializeShortcuts).toBeDefined();
            expect(c.parentData.datesLogicComparisonType).toEqual('abc');
        });
    });

    describe('dirty check', function() {
        it('should return true if form dirty or grid dirty', function() {
            var c = controller();
            c.form = {
                $dirty: true
            };
            kendoGridService.isGridDirty.returnValue = false;
            expect(c.topic.isDirty()).toBe(true);

            c.form.$dirty = false;
            kendoGridService.isGridDirty.returnValue = true;
            expect(c.topic.isDirty()).toBe(true);
        });

        it('should return false if form is not dirty', function() {
            var c = controller();
            c.form = {
                $dirty: false
            };
            kendoGridService.isGridDirty.returnValue = false;
            
            expect(c.topic.isDirty()).toBe(false);
        });
    });

    describe('showComparisonOperator', function() {
        it('returns empty string if no comparisonOperator', function() {
            var c = controller();
            var r = c.showComparisonOperator({});

            expect(r).toBe('');
        });

        it('returns dataItem comparisonOperator value', function() {
            var c = controller();
            var r = c.showComparisonOperator({
                comparisonOperator: {
                    value: 123
                }
            });

            expect(r).toBe(123);
        });
    });

    describe('enabling comparison options', function() {
        it('disables options when cannot edit', function() {
            var c = controller();

            c.canEdit = false;
            c.gridOptions.dataSource = {
                data: _.constant(['a'])
            };

            var result = c.comparisonOptionsDisabled();
            expect(result).toBe(true);
        });

        it('disables options when no date comparisons', function() {
            var c = controller();

            c.canEdit = true;
            c.gridOptions.dataSource = {
                data: _.constant([])
            };

            var result = c.comparisonOptionsDisabled();
            expect(result).toBe(true);
        });

        it('enables options when editable and has date comparisons', function() {
            var c = controller();

            c.canEdit = true;
            c.gridOptions.dataSource = {
                data: _.constant(['a'])
            };

            var result = c.comparisonOptionsDisabled();
            expect(result).toBe(false);
        });
    });

    describe('format Compare With column ', function(){
        it('formats empty column', function(){
            var c = controller();
            expect(c.formatCompareWith({comparisonOperator:{key: 'EX'}})).toBe('');
        });
        
        it('formats event description', function(){
            var c = controller();
            c.formatCompareWith({eventB: 'assigned', compareDate: 'itnored and does not matter'});
            expect(service.formatPicklistColumn).toHaveBeenCalledWith('assigned');
        });

        it('returns compare date', function(){
            var c = controller();
            c.formatCompareWith({compareDate: 'some date'});
            expect(dateService.format).toHaveBeenCalledWith('some date');
        });
        
        it('returns system date', function(){
            var c = controller();
            c.formatCompareWith({compareDate: null, eventB: null});
            expect(translate.instant).toHaveBeenCalledWith('workflows.eventcontrol.dateComparison.maintenance.systemDate');
        });
    });

    describe('get form data ', function() {
        it('returns date comparison option', function() {
            var c = controller();

            c.gridOptions.dataSource = {
                data: _.constant([])
            };

            c.formData.datesLogicComparisonType = 'c';

            var result = c.topic.getFormData();
            expect(result.datesLogicCompare).toBe('c');
        });

        it('calls mapGridDelta', function() {
            var c = controller();
            var item = {
                isAdded: true,
                eventA: {
                    key: 'a'
                },
                comparisonOperator: {
                    key: 'b'
                }
            };

            c.gridOptions.dataSource = {
                data: _.constant([item])
            };

            c.topic.getFormData();

            expect(service.mapGridDelta).toHaveBeenCalledWith([item], jasmine.any(Function));
        });
    });
});
