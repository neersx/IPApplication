describe('inprotech.configuration.general.numbertypes.service', function() {
    'use strict';

    var service, httpMock;

    beforeEach(function() {
        module('inprotech.configuration.general.numbertypes');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function(numberTypesService) {
        service = numberTypesService;
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

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/numbertypes/search', {
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

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/numbertypes/search', {
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

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/numbertypes/search', {
                params: {
                    q: JSON.stringify(criteria),
                    params: JSON.stringify(queryParams)
                }
            });
        });
    });
    it('get should make backend call to fetch the record', function() {
        service.get(1);

        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/numbertypes/1');
    });
    it('add should make backend call for post', function() {
        var entity = {
            numberTypeCode: 'A'
        };
        service.add(entity);

        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/numbertypes/', entity);
    });
    it('update should make backend call for post', function() {
        var entity = {
            id: 1,
            numberTypeCode: 'A'
        };
        service.update(entity);

        expect(httpMock.put).toHaveBeenCalledWith('api/configuration/numbertypes/' + entity.id, entity);
    });
    it('change number type should make backend call for put', function() {
        var entity = {
            id: 1,
            numberTypeCode: 'A',
            newNumberTypeCode: 'B'
        };
        service.changeNumberTypeCode(entity);

        expect(httpMock.put).toHaveBeenCalledWith('api/configuration/numbertypes/' + entity.id + '/numbertypecode', entity);
    });
    it('update Number Types Sequence should make backend call for put', function() {
        var entity = {};
        service.updateNumberTypesSequence(entity);

        expect(httpMock.put).toHaveBeenCalledWith('api/configuration/numbertypes/update-number-types-sequence', entity);
    });
    it('persistSavedNumberTypes should set saved property to true', function() {
        var dataSource = [{
            id: 1,
            numberTypeCode: 'A'
        }, {
            id: 2,
            numberTypeCode: 'B'
        }, {
            id: 3,
            numberTypeCode: 'C'
        }];

        service.savedNumberTypeIds = [1, 3];

        service.persistSavedNumberTypes(dataSource);
        expect(dataSource[0].saved).toBe(true);
        expect(dataSource[2].saved).toBe(true);
    });
    it('delete should make http post backend call with ids', function() {
        var selectedItems = [{ id: 1 }, { id: 2 }];

        service.delete(selectedItems);
        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/numbertypes/delete', {
            ids: [1, 2]
        });
    });
    it('markInUseNumberTypes should mark number types with truthy inUse value', function() {
        var numberTypes = [{
            id: 1
        }, {
            id: 2,
            inUse: false
        }, {
            id: 3,
            inUse: true
        }];

        var inUseIds = [1, 2];
        service.markInUseNumberTypes(numberTypes, inUseIds);
        expect(numberTypes[0].inUse).toBeTruthy();
        expect(numberTypes[1].inUse).toBeTruthy();
    });
});