namespace inprotech.configuration.general.names.namerelations {
    describe('inprotech.configuration.general.names.namerelations.NameRelationService', () => {
        'use strict';

        let service: INameRelationService, httpMock: any;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.names.namerelations');

            angular.mock.module(function ($provide) {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);

                httpMock = $injector.get('httpMock');
                $provide.value('$http', httpMock);
            });
        });

        beforeEach(inject((NameRelationService: INameRelationService) => {
            service = NameRelationService;
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

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/names/namerelation/search', {
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

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/names/namerelation/search', {
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

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/names/namerelation/search', {
                    params: {
                        q: JSON.stringify(criteria),
                        params: JSON.stringify(queryParams)
                    }
                });
            });
        });
        it('get should make backend call to fetch the record', () => {
            service.get(1);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/names/namerelation/1');
        });
        it('add should make backend call for post', () => {
            let entity: INameRelation = {
                id: null,
                selected: true,
                inUse: true,
                saved: false
            };
            service.add(entity);

            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/names/namerelation/', entity);
        });
        it('update should make backend call for post', () => {
            let entity: INameRelation = {
                id: 1,
                selected: true,
                inUse: true,
                saved: false
            };
            service.update(entity);

            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/names/namerelation/' + entity.id, entity);
        });
        it('persistSavedNameRelationship should set saved property to true', () => {
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

            service.persistSavedNameRelationship(dataset);
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
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/names/namerelation/delete', {
                ids: [1, 2]
            });
        });
        it('markInUseNameRelationship should mark name relationship with truthy inUse value', () => {
            let namerelations = [{
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
            service.markInUseNameRelationship(namerelations, inUseIds);
            expect(namerelations[0].inUse).toBeTruthy();
            expect(namerelations[1].inUse).toBeTruthy();
            expect(namerelations[2].inUse).toBeFalsy();
        });
    });
}
