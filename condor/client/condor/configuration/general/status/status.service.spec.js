describe('inprotech.configuration.general.status.service', function() {
    'use strict';

    var service, httpMock

    beforeEach(function() {
        module('inprotech.configuration.general.status');
        module(function($provide) {
            var $injector = angular.injector(['inprotech.mocks']);
            httpMock = $injector.get('httpMock');

            $provide.value('$http', httpMock);
        });
    });

    beforeEach(inject(function(statusService) {
        service = statusService;
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

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/status', {
                params: {
                    q: JSON.stringify(query)
                }
            });
        });

        it('should accept empty criteria', function() {
            var criteria = {};

            var query = {
                text: ''
            };

            service.search(criteria);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/status', {
                params: {
                    q: JSON.stringify(query)
                }
            });
        });
    });
    describe('get', function() {
        it('should make backend call to fetch the record', function() {
            service.get(1);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/status/1');
        });
    });
    describe('add', function() {
        it('should make backend call for post', function() {
            var entity = {
                id: 1
            };
            service.add(entity);

            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/status/', entity);
        });
    });
    describe('update', function() {
        it('should make backend call for put', function() {
            var entity = {
                id: 1
            };
            service.update(entity);

            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/status/' + entity.id, entity);
        });
    });
    describe('delete', function() {
        it('should make http post backend call with ids', function() {
            var selectedItems = [{
                id: 1
            }, {
                id: 2
            }];

            service.delete(selectedItems);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/status/delete', {
                ids: [1, 2]
            });
        });
    });
    describe('persistSavedStatuses', function() {
        it('should set saved property to true', function() {
            var gridData = [{
                id: 1
            }, {
                id: 2
            }, {
                id: 3
            }];

            service.savedStatusIds = [1, 3];

            service.persistSavedStatuses(gridData);
            expect(gridData[0].saved).toBe(true);
            expect(gridData[2].saved).toBe(true);
        });
    });
    describe('markInUseStatuses', function() {
        it('should mark statuses with truthy inUse value', function() {
            var gridData = [{
                id: 1
            }, {
                id: 2,
                inUse: false
            }, {
                id: 3,
                inUse: true
            }];

            var inUseIds = [1, 2];
            service.markInUseStatuses(gridData, inUseIds);
            expect(gridData[0].inUse).toBeTruthy();
            expect(gridData[1].inUse).toBeTruthy();
        });
    });
});
