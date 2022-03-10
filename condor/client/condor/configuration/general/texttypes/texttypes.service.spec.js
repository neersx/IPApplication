describe('inprotech.configuration.general.texttypes.service', function() {
    'use strict';

    var service, httpMock;

    beforeEach(function() {
        module('inprotech.configuration.general.texttypes');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function(textTypesService) {
        service = textTypesService;
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

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/texttypes/search', {
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

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/texttypes/search', {
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

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/texttypes/search', {
                params: {
                    q: JSON.stringify(criteria),
                    params: JSON.stringify(queryParams)
                }
            });
        });
    });
    it('find should fetch the selected record', function() {
        service.searchResults.data = [{
            id: 'A',
            description: 'Abstract'
        }, {
            id: 'C',
            description: 'Claims'
        }];

        var result = service.find('A');
        expect(result.id).toEqual('A');
    });
    it('get should make backend call to fetch the record', function() {
        service.get('A');

        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/texttypes/A');
    });
    it('add should make backend call for post', function() {
        var entity = {
            id: 'A'
        };
        service.add(entity);

        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/texttypes/', entity);
    });
    it('update should make backend call for post', function() {
        var entity = {
            id: "A",
            description: 'aaa'
        };
        service.update(entity);

        expect(httpMock.put).toHaveBeenCalledWith('api/configuration/texttypes/' + entity.id, entity);
    });
    it('resetSavedValue should set saved property to false', function() {
        service.searchResults = [{
            id: 'A',
            saved: true
        }, {
            id: 'B',
            saved: true
        }];

        service.resetSavedValue('A');
        expect(service.searchResults[0].saved).toBe(false);
    });
    it('persistSavedTextTypes should set saved property to true', function() {
        service.searchResults = [{
            id: 'A'
        }, {
            id: 'B'
        }, {
            id: 'C'
        }];

        service.savedTextTypeIds = ['A', 'C'];

        service.persistSavedTextTypes();
        expect(service.searchResults[0].saved).toBe(true);
        expect(service.searchResults[2].saved).toBe(true);
    });
    it('delete should make http post backend call with ids', function() {
        var selectedItems = [{
            id: 'A'
        }, {
            id: 'B'
        }];

        service.delete(selectedItems);
        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/texttypes/delete', {
            ids: ['A', 'B']
        });
    });
    it('markInUseTextTypes should mark text types with truthy inUse value', function() {
        var texttypes = [{
            id: 'A'
        }, {
            id: 'B',
            inUse: false
        }, {
            id: 'C',
            inUse: true
        }];

        var inUseIds = ['A', 'B'];
        service.markInUseTextTypes(texttypes, inUseIds);
        expect(texttypes[0].inUse).toBeTruthy();
        expect(texttypes[1].inUse).toBeTruthy();
    });
    it('change text type should make backend call for put', function() {
        var entity = {
            id: 'A',
            newTextTypeCode: 'B'
        };
        service.changeTextTypeCode(entity);

        expect(httpMock.put).toHaveBeenCalledWith('api/configuration/texttypes/' + entity.id + '/texttypecode', entity);
    });
});
