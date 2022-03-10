describe('inprotech.configuration.rules.workflows.WorkflowsSearchController', function() {
    'use strict';

    var controller, kendoGridBuilder, sharedService, state, bulkMenuOperationsMock, workflowsSearchService, modalService, rootScope;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function() {
            bulkMenuOperationsMock = test.mock('BulkMenuOperations');
            kendoGridBuilder = test.mock('kendoGridBuilder');
        });

        inject(function($controller, $state, $q, $rootScope) {
            rootScope = $rootScope;
            state = $state;
            sharedService = {
                reset: angular.noop,
                hasOffices: angular.noop
            };

            workflowsSearchService = {
                getColumnFilterData: jasmine.createSpy()
            };

            modalService = {
                open: jasmine.createSpy().and.returnValue($q.when({}))
            }

            controller = function(dependencies) {
                dependencies = angular.extend({
                    $scope: $rootScope.$new,
                    $element: {},
                    viewData: {
                        hasOffices: true
                    },
                    sharedService: sharedService,
                    workflowsSearchService: workflowsSearchService,
                    modalService: modalService
                }, dependencies);

                var c = $controller('WorkflowsSearchController', dependencies);
                c.$onInit();
                spyOn(c, 'search').and.callThrough();

                return c;
            };
        });
    });

    describe('initialise', function() {
        it('should initialise controller', function() {
            var c = controller();

            expect(c.searchBy).toBe('characteristics');
            expect(sharedService.hasOffices).toBe(true);
        });

        it('should initialise grid', function() {
            var c = controller();

            expect(kendoGridBuilder.buildOptions).toHaveBeenCalled();
            expect(c.gridOptions).toBeDefined();
            expect(c.menu).toBeDefined();
        });

        it('should initialise the menu', function() {
            var c = controller();
            c.gridOptions.pageable = {
                pageSize: 99
            }
            c.menuInitialised();
            expect(bulkMenuOperationsMock.prototype.initialiseMenuForPaging).toHaveBeenCalledWith(99);
        });
    });

    describe('grid options', function() {
        it('should call selection changed on data created', function() {
            var c = controller();
            c.gridOptions.onDataCreated();
            expect(bulkMenuOperationsMock.prototype.selectionChange).toHaveBeenCalled();
        });

        it('should read filter metadata', function() {
            var c = controller();
            var columns = {
                a: 'a'
            };
            var filters = {};
            c.gridOptions.getFiltersExcept = jasmine.createSpy().and.returnValue(filters);
            c.gridOptions.readFilterMetadata(columns);
            expect(workflowsSearchService.getColumnFilterData).toHaveBeenCalledWith(columns, filters);
            expect(c.gridOptions.getFiltersExcept).toHaveBeenCalledWith(columns);
        });
    });

    describe('reset', function() {
        it('should clear and reset', function() {
            var c = controller();

            c.gridOptions.clear = jasmine.createSpy();

            c.searchBy = 'a';
            sharedService.a = {
                reset: jasmine.createSpy()
            };

            c.reset();

            expect(c.gridOptions.clear).toHaveBeenCalled();
            expect(sharedService.a.reset).toHaveBeenCalled();
        });
    });

    describe('search', function() {
        it('should perform search', function() {
            var c = controller();
            c.search();

            expect(c.gridOptions.search).toHaveBeenCalled();
        });

        describe('and then', function() {
            var c, returnData, thenCallback, queryParams;
            beforeEach(function() {
                c = controller();
                queryParams = {};
                c.searchBy = 'a';

                returnData = {
                    data: [{
                        id: 1
                    }, {
                        id: 2
                    }],
                    pagination: {}
                };

                thenCallback = jasmine.createSpy('thenCallbackSpy', function(callback) {
                    return callback(returnData);
                }).and.callThrough();

                sharedService.a = {
                    search: function() {
                        return {
                            then: thenCallback
                        };
                    }
                };

                spyOn(sharedService.a, 'search').and.callThrough();

            });

            it('invokes service to get data and invoke callback', function() {
                c.gridOptions.read(queryParams);

                expect(sharedService.a.search).toHaveBeenCalledWith(queryParams);
                expect(thenCallback).toHaveBeenCalled();
            });

            it('invokes setAllIds if all results fit on one page', function() {
                sharedService.lastSearch = {
                    setAllIds: jasmine.createSpy()
                };

                queryParams.take = 2;
                returnData.pagination.total = 1;

                c.gridOptions.read(queryParams);

                expect(sharedService.lastSearch.setAllIds).toHaveBeenCalledWith([1, 2]);
            });

            it('returns the data from the server', function() {
                var r = c.gridOptions.read(queryParams);
                expect(r).toEqual(returnData);
            });
            it('should return imporved no results msg when the selected match type is best criteria', function() {
                sharedService.characteristics= {
                    selectedMatchType: function() {
                        return 'best-criteria-only';
                    }
                };
                var c = controller();
                var noResultsText = c.noResultsHint();
                expect(noResultsText).toEqual('workflows.search.noResultsHintBestCriteriaAndMatch');
            });
            it('should return imporved no results msg when the selected match type is best-matches', function() {
                sharedService.characteristics= {
                    selectedMatchType: function() {
                        return 'best-match';
                    }
                };
                var c = controller();
                var noResultsText = c.noResultsHint();
                expect(noResultsText).toEqual('workflows.search.noResultsHintBestCriteriaAndMatch');
            });
            it('should return no results when the selected match type is neither best-matches nor best criteria', function() {
                sharedService.characteristics= {
                    selectedMatchType: function() {
                        return 'something else';
                    }
                };
                var c = controller();
                var noResultsText = c.noResultsHint();
                expect(noResultsText).toEqual('noResultsFound');
            });
        });
    });

    describe('bulk menu', function() {
        var c;
        beforeEach(function() {
            c = controller();
            spyOn(c.gridOptions, 'data').and.returnValue('abc');
        });

        it('should build the menu', function() {
            expect(c.menu).toEqual(jasmine.objectContaining({
                context: 'workflowSearch',
                items: [jasmine.objectContaining({
                    id: 'viewInheritance',
                    text: 'workflows.search.viewInheritance',
                    icon: 'inheritance',
                    enabled: jasmine.any(Function),
                    click: jasmine.any(Function)
                })],
                clearAll: jasmine.any(Function),
                selectPage: jasmine.any(Function),
                selectionChange: jasmine.any(Function)
            }));
        });

        it('should clear all', function() {
            c.menu.clearAll();
            expect(bulkMenuOperationsMock.prototype.clearAll).toHaveBeenCalledWith('abc');
            expect(c.gridOptions.data).toHaveBeenCalled();
        });

        it('should select page', function() {
            c.menu.selectPage(true);
            expect(bulkMenuOperationsMock.prototype.selectPage).toHaveBeenCalledWith('abc', true);
            expect(c.gridOptions.data).toHaveBeenCalled();
        });

        it('should handle a selection change', function() {
            var dataItem = 'abc';
            c.menu.selectionChange(dataItem);
            expect(bulkMenuOperationsMock.prototype.singleSelectionChange).toHaveBeenCalledWith('abc', 'abc');
            expect(c.gridOptions.data).toHaveBeenCalled();
        });

        describe('view inheritance item', function() {
            it('should configure view inheritance item', function() {
                bulkMenuOperationsMock.prototype.anySelected.and.returnValue(false);
                var result = c.menu.items[0].enabled();
                expect(bulkMenuOperationsMock.prototype.anySelected).toHaveBeenCalledWith('abc');
                expect(c.gridOptions.data).toHaveBeenCalled();
                expect(result).toBe(false);
            });

            it('should enable if there are items', function() {
                bulkMenuOperationsMock.prototype.anySelected.and.returnValue(true);
                var result = c.menu.items[0].enabled();
                expect(result).toBe(true);
            });

            it('should open inheritance tree on click', function() {
                c.gridOptions.data.and.returnValue([{
                    id: 1,
                    selected: true
                }, {
                    id: 3,
                    selected: false
                }, {
                    id: 9,
                    selected: true
                }]);

                bulkMenuOperationsMock.prototype.selectedRecords.and.returnValue([{
                    id: 1,
                    selected: true
                },
                {
                    id: 9,
                    selected: true
                }]);

                c.menu.selectionChange(c.gridOptions.data()[0]);
                c.menu.selectionChange(c.gridOptions.data()[2]);
                expect(bulkMenuOperationsMock.prototype.singleSelectionChange).toHaveBeenCalled();

                spyOn(state, 'go');
                c.menu.items[0].click();
                expect(bulkMenuOperationsMock.prototype.selectedRecords).toHaveBeenCalled();

                expect(state.go).toHaveBeenCalledWith('workflows.inheritance', {
                    criteriaIds: '1,9'
                });
            });
        });
    });

    describe('Create Criteria', function() {
        it('opens create crietria modal, when choosen', function() {
            sharedService = {
                reset: angular.noop,
                characteristics: { characteristicsSelected: jasmine.createSpy() }
            }
            var c = controller();
            c.openCharacteristicModal();

            rootScope.$apply();
            expect(modalService.open).toHaveBeenCalled();
            expect(sharedService['characteristics'].characteristicsSelected).toHaveBeenCalled();
        });
    });

    it('should navigate to right place', function() {
        sharedService = {
            reset: angular.noop,
            hasOffices: angular.noop,
            lastSearch: {
                args: [{
                    event: {
                        whatEver: 'whatEver'
                    }
                }]
            },
            selectedEventInDetail: null
        };
        var c = controller();
        var dataItemId = 123;

        expect(state.href('workflows')).toEqual('#/configuration/rules/workflows');

        c.prepareToGoDetail(dataItemId);

        expect(state.href('workflows.details', {
            id: dataItemId
        })).toEqual('#/configuration/rules/workflows/' + dataItemId);
        expect(sharedService.selectedEventInDetail).toBe(sharedService.lastSearch.args[0].event);
        expect(sharedService.activeTopicKey).toBe(null);
    });
});
