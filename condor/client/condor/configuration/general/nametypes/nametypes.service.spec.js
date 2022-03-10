describe('inprotech.configuration.general.nametypes.service', function() {
    'use strict';

    var service, httpMock;

    beforeEach(function() {
        module('inprotech.configuration.general.nametypes');

        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);

            httpMock = $injector.get('httpMock');
            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function(nameTypesService) {
        service = nameTypesService;
    }));

    describe('searching', function() {
        it('should pass correct parameters', function() {
            var criteria = {
                text: 'text'
            };

            var query = {
                text: 'text'
            };

            service.search(criteria);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/nametypes/search', {
                params: {
                    q: JSON.stringify(query)
                }
            });
        });

        it('should accept empty criteria', function() {
            var criteria = {};

            service.search(criteria);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/nametypes/search', {
                params: {
                    q: JSON.stringify(criteria)
                }
            });
        });
    });
    it('get should make backend call to fetch the record', function() {
        service.get(1);

        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/nametypes/1');
    });
    it('add should make backend call for post', function() {
        var entity = {
            id: 1,
            nameTypeCode: 'A'
        };
        service.add(entity);

        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/nametypes/', entity);
    });
    it('update should make backend call for post', function() {
        var entity = {
            id: 1,
            nameTypeCode: 'A'
        };
        service.update(entity);

        expect(httpMock.put).toHaveBeenCalledWith('api/configuration/nametypes/' + entity.id, entity);
    });
    it('persistSavedNameTypes should set saved property to true', function() {
        var dataSource = [{
            id: 1,
            nameTypeCode: 'A'
        }, {
            id: 2,
            nameTypeCode: 'B'
        }, {
            id: 3,
            nameTypeCode: 'C'
        }];

        service.savedNameTypeIds = [1, 3];

        service.persistSavedNameTypes(dataSource);
        expect(dataSource[0].saved).toBe(true);
        expect(dataSource[2].saved).toBe(true);
    });
    it('delete should make http post backend call with ids', function() {
        var selectedItems = [{ id: 1 }, { id: 2 }];

        service.delete(selectedItems);
        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/nametypes/delete', {
            ids: [1, 2]
        });
    });
    it('markInUseNameTypes should mark name types with truthy inUse value', function() {
        var nameTypes = [{
            id: 1
        }, {
            id: 2,
            inUse: false
        }, {
            id: 3,
            inUse: true
        }];

        var inUseIds = [1, 2];
        service.markInUseNameTypes(nameTypes, inUseIds);
        expect(nameTypes[0].inUse).toBeTruthy();
        expect(nameTypes[1].inUse).toBeTruthy();
    });
    it('update Name Types Sequence should make backend call for put', function() {
        var entity = {};
        service.updateNameTypesSequence(entity);

        expect(httpMock.put).toHaveBeenCalledWith('api/configuration/nametypes/updatenametypessequence', entity);
    });
});