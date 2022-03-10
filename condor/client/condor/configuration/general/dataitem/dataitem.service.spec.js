describe('inprotech.configuration.general.dataitem.service', function() {
    'use strict';

    var service, httpMock

    beforeEach(function() {
        module('inprotech.configuration.general.dataitem');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);
            httpMock = $injector.get('httpMock');

            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function(dataItemService) {
        service = dataItemService;
    }));


    describe('searching', function() {
        it('should pass correct parameters', function() {
            var criteria = {
                text: 'text'
            };

            var queryParams = {
                sortBy: "text",
                sortDir: 'asc'
            };

            service.search(criteria, queryParams);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/dataitems/search', {
                params: {
                    q: JSON.stringify(criteria),
                    params: JSON.stringify(queryParams)
                }
            });
        });

        it('should accept empty criteria', function() {
            var criteria = {};

            var queryParams = {
                sortBy: "text",
                sortDir: 'asc'
            };

            service.search(criteria, queryParams);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/dataitems/search', {
                params: {
                    q: JSON.stringify(criteria),
                    params: JSON.stringify(queryParams)
                }
            });
        });

        it('should accept empty params', function() {
            var criteria = {};
            var queryParams = null;

            service.search(criteria, queryParams);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/dataitems/search', {
                params: {
                    q: JSON.stringify(criteria),
                    params: JSON.stringify(queryParams)
                }
            });
        });
    });
    describe('getColumnFilterData', function() {
        it('should get filter data', function() {
            var criteria = {
                text: 'text'
            };
            var query = {
                text: 'text'
            };
            service.search(criteria);

            httpMock.get.calls.reset();

            service.getColumnFilterData({
                field: 'field'
            });

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/dataitems/filterdata/field', {
                params: {
                    criteria: JSON.stringify(query)
                }
            });
        });
    });

    describe('save', function() {
        it('add should make backend call for post', function() {
            var entity = {
                id: 1,
                name: 'A',
                description: 'Desc'
            };
            service.add(entity);

            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/dataitems/', entity);
        });
         it('update should make backend call for post', function() {
            var entity = {
                id: 1,
                name: 'A',
                description: 'Desc'
            };
            service.update(entity);

            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/dataitems/' + entity.id, entity);
        });

        it('persistSavedDataItems should set saved property to true', function() {
            var dataSource = [{
                id: 1,
                name: 'A'
            }, {
                id: 2,
                name: 'B'
            }, {
                id: 3,
                name: 'C'
            }];

            service.savedDataItemIds = [1, 3];

            service.persistSavedDataItems(dataSource);
            expect(dataSource[0].saved).toBe(true);
            expect(dataSource[2].saved).toBe(true);
        });

        it('delete should make http post backend call with ids', function() {
        var selectedItems = [{ id: 1 }, { id: 2 }];

        service.delete(selectedItems);
        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/dataitems/delete', {
            ids: [1, 2]
        });
    });
    });
    describe('Validate', function() {
        it('validate should make backend call for post', function() {
            var entity = {
                id: 1,
                name: 'A',
                description: 'Desc'
            };
            service.validate(entity);

            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/dataitems/validate', entity);
        });
    });
});