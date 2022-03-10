describe('inprotech.configuration.rules.workflows.workflowsSearchService', function() {
    'use strict';

    var service, httpMock, queryParams, sharedService, characteristicsBuilder, store;

    beforeEach(function() {
        module('inprotech.configuration.rules.workflows');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);

            store = $injector.get('storeMock');
            $provide.value('store', store);

            $injector = angular.injector(['inprotech.mocks.configuration.rules.workflows']);
            characteristicsBuilder = $injector.get('characteristicsBuilderMock');
            $provide.value('characteristicsBuilder', characteristicsBuilder);
                             

            sharedService = {
                lastSearch: null
            };
            $provide.value('sharedService', sharedService);
        });

        inject(function(workflowsSearchService) {
            service = workflowsSearchService;

            queryParams = {
                sortBy: 'id',
                sortDir: 'asc',
                skip: 1,
                take: 2
            };
        });
    });

    describe('searching by ids', function() {
        var selectedCriteria, query;
        beforeEach(function() {
            selectedCriteria = [{
                id: 1,
                description: 'abc'
            }, {
                id: 2,
                description: 'def'
            }];

            query = [1, 2];
        });

        it('should make api call with correct parameters', function() {
            service.searchByIds(selectedCriteria, queryParams);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/searchByIds', {
                params: {
                    q: JSON.stringify(query),
                    params: JSON.stringify(queryParams)
                }
            });
            expect(store.local.set).toHaveBeenCalled();
        });

        it('should accept empty criteria', function() {
            service.searchByIds({});

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/searchByIds', {
                params: {
                    q: '[]',
                    params: undefined
                }
            });
            expect(store.local.set).toHaveBeenCalled();
        });

        it('should return data', function() {
            var data = [{
                id: 1
            }];
            httpMock.get.returnValue = data;

            var result = service.searchByIds(selectedCriteria, queryParams);

            expect(result).toBe(data);
        });

        it('sets the last search into shared service', function() {
            var searchCriteria = {
                id: 1
            };

            service.searchByIds(searchCriteria);
            expect(sharedService.lastSearch.args[0].id).toBe(1);
        });
    });

    describe('searching by characteristics', function() {
        it('should make api call with correct parameters', function() {
            var searchCriteria = 'a';

            characteristicsBuilder.build.returnValue = 'b';
            service.search(searchCriteria, queryParams);

            expect(characteristicsBuilder.build).toHaveBeenCalledWith(searchCriteria);
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/search', {
                params: {
                    criteria: JSON.stringify('b'),
                    params: JSON.stringify(queryParams)
                }
            });
        });

        it('should return data', function() {
            var data = [{
                id: 1
            }];
            httpMock.get.returnValue = data;

            var result = service.search();

            expect(result).toBe(data);
        });

        it('sets the last search into shared service', function() {
            var searchCriteria = {
                id: 1
            };

            service.search(searchCriteria);
            expect(sharedService.lastSearch.args[0].id).toBe(1);
        });
    });

    describe('getColumnFilterData', function() {

        it('should get filter data if no last sarch', function() {

            httpMock.get.calls.reset();

            service.getColumnFilterData({
                field: 'field'
            }, 'existingColumnFilters').then(function(d) {
                expect(d.value).toEqual([]);
              }); 
        });
        it('should get filter data if previous call was searchByIds', function() {
            service.searchByIds([{
                id: 'id'
            }]);

            httpMock.get.calls.reset();

            service.getColumnFilterData({
                field: 'field'
            }, 'existingColumnFilters');

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/filterdatabyids/field', {
                params: {
                    q: JSON.stringify(['id']),
                    columnFilters: JSON.stringify('existingColumnFilters')
                }
            });
        });

        it('should get filter data if previous call was search', function() {
            service.search('searchCriteria');
            characteristicsBuilder.build.returnValue = 'characteristics';

            httpMock.get.calls.reset();

            service.getColumnFilterData({
                field: 'field'
            }, 'existingColumnFilters');

            expect(characteristicsBuilder.build).toHaveBeenCalledWith('searchCriteria');
            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/filterdata/field', {
                params: {
                    criteria: JSON.stringify('characteristics'),
                    columnFilters: JSON.stringify('existingColumnFilters')
                }
            });
        });
    });

    it('getCaseCharacteristics should use correct parameters', function() {
        service.getCaseCharacteristics(1);

        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/characteristics/caseCharacteristics/1?purposeCode=E');
    });

    it('getDefaultDateOfLaw should use correct parameters', function() {
        service.getDefaultDateOfLaw(1, 2);

        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/rules/workflows/defaultDateOfLaw', {
            params: {
                caseId: 1,
                actionId: 2
            }
        });
    });
});
