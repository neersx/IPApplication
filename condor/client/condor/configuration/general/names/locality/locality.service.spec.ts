namespace inprotech.configuration.general.names.locality {
    describe('inprotech.configuration.general.names.locality.LocalityService', () => {
        'use strict';

        let service: ILocalityService, httpMock: any;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.names.locality');

            angular.mock.module(function ($provide) {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);

                httpMock = $injector.get('httpMock');
                $provide.value('$http', httpMock);
            });
        });

        beforeEach(inject((LocalityService: ILocalityService) => {
            service = LocalityService;
        }));

        describe('searching', () => {
            it('should pass correct parameters', () => {
                let criteria = {
                    text: 'text'
                };

                let queryParams = {
                    sortBy: 'text',
                    sortDir: 'asc'
                };

                service.search(criteria, queryParams);

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/names/locality/search', {
                    params: {
                        q: JSON.stringify(criteria),
                        params: JSON.stringify(queryParams)
                    }
                });
            });

            it('should accept empty criteria', () => {
                let criteria = {};
                let queryParams = {
                    sortBy: 'text',
                    sortDir: 'asc'
                };

                service.search(criteria, queryParams);

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/names/locality/search', {
                    params: {
                        q: JSON.stringify(criteria),
                        params: JSON.stringify(queryParams)
                    }
                });
            });

            it('should accept empty params', () => {
                let criteria = {};
                let queryParams = null;

                service.search(criteria, queryParams);

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/names/locality/search', {
                    params: {
                        q: JSON.stringify(criteria),
                        params: JSON.stringify(queryParams)
                    }
                });
            });
        });
        it('get should make backend call to fetch the record', () => {
            service.get(1);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/names/locality/1');
        });
        it('add should make backend call for post', () => {
            let entity: ILocality = {
                id: null,
                selected: true,
                inUse: true,
                saved: false
            };
            service.add(entity);

            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/names/locality/', entity);
        });
        it('update should make backend call for post', () => {
            let entity: ILocality = {
                id: 1,
                selected: true,
                inUse: true,
                saved: false
            };
            service.update(entity);

            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/names/locality/' + entity.id, entity);
        });
        it('persistSavedLocalities should set saved property to true', () => {
            let dataset = [{
                id: 1,
                selected: true,
                inUse: true,
                saved: false
            }, {
                id: 2,
                selected: true,
                inUse: true,
                saved: false

            }, {
                id: 3,
                selected: true,
                inUse: true,
                saved: false

            }];

            service.savedIds = [1, 3];

            service.persistSavedLocalities(dataset);
            expect(dataset[0].saved).toBe(true);
            expect(dataset[2].saved).toBe(true);
        });
        it('delete should make http post backend call with ids', () => {
            let selectedItems = [{
                id: 1,
                saved: false
            }, {
                id: 2,
                saved: false
            }];

            service.deleteSelected(selectedItems);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/names/locality/delete', {
                ids: [1, 2]
            });
        });
        it('markInUseLocalities should mark locality with truthy inUse value', () => {
            let localities = [{
                id: 1,
                inUse: false
            }, {
                id: 2,
                inUse: false
            }, {
                id: 3,
                inUse: false
            }];

            let inUseIds = [1, 2];
            service.markInUseLocalities(localities, inUseIds);
            expect(localities[0].inUse).toBeTruthy();
            expect(localities[1].inUse).toBeTruthy();
            expect(localities[2].inUse).toBeFalsy();
        });
    });
}
