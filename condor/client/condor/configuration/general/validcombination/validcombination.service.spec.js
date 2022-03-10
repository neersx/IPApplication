describe('inprotech.configuration.general.validcombination.validCombinationService', function() {
    'use strict';

    var service, httpMock, queryParams, characterstic, entity;

    beforeEach(function() {
        module('inprotech.configuration.general.validcombination');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function(validCombinationService) {
        service = validCombinationService;

        queryParams = {
            sortBy: 'country',
            sortDir: 'asc',
            skip: 1,
            take: 2
        };

        characterstic = {
            type: 'propertyType'
        };

        entity = {
            id: {
                countryId: 'A',
                propertyTypeId: 'A'
            },
            countryId: 'A',
            propertyTypeId: 'A'
        };
    }));

    describe('searching by validcombination', function() {
        it('should make api call with correct parameters', function() {
            var searchCriteria = {
                propertyType: 'a'
            };
            var searchType = 'propertyType';

            httpMock.get.returnValue = {
                data: {}
            };

            service.search(searchCriteria, queryParams, searchType);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/validcombination/propertyType/search', {
                params: {
                    criteria: JSON.stringify({
                        propertyType: 'a'
                    }),
                    params: queryParams
                }
            });
        });
        it('should accept empty criteria', function() {
            httpMock.get.returnValue = {
                data: {}
            };
            service.search({}, queryParams, 'propertyType');

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/validcombination/propertyType/search', {
                params: {
                    criteria: JSON.stringify({}),
                    params: queryParams
                }
            });
        });

        it('should return data', function() {
            var data = {
                data: [{
                propertyType: 'Patent',
                country: 'Australia'
            }]
            };
            httpMock.get.returnValue = data;

            var result = service.search();

            expect(result).toBe(data);
        });
    });
    it('getSelectedEntity should make backend call to fetch the record', function() {
        service.get(entity.id, characterstic);

        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/validcombination/propertyType', {
            params: {
                entitykey: JSON.stringify(entity.id)
            }
        });
    });
    it('add should make backend call for post', function() {

        service.add(entity, characterstic);

        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/validcombination/propertyType', entity);
    });
    it('update should make backend call for post', function() {
        service.update(entity, characterstic);

        expect(httpMock.put).toHaveBeenCalledWith('api/configuration/validcombination/propertyType', entity);
    });
    it('delete should make http post backend call with keys', function() {
        var entityKeys = [{
            id: {
                countryId: 'A',
                propertyTypeId: 'A'
            }
        }, {
            id: {
                countryId: 'A',
                propertyTypeId: 'B'
            }
        }];

        service.delete(entityKeys, characterstic);
        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/validcombination/propertyType/delete', JSON.stringify(entityKeys));
    });    
    it('copy should make backend call for post', function() {
        var copyEntity = {};
        service.copy(copyEntity);

        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/validcombination/copy', copyEntity);
    });
    it('validateCategory should make backend call to fetch the result', function() {
        var caseType = 'A';
        var caseCategory = 'N';
        var data = {
            result: {
                isValid: true
            }
        };
        httpMock.get.returnValue = data;

        var response = service.validateCategory(caseType, caseCategory, 'category');

        expect(httpMock.get.calls.mostRecent().args[0]).toBe('api/configuration/validcombination/category/validateCategory');
        expect(response).toBe(data.result);
    });
});
