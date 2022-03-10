namespace inprotech.configuration.general.names.namealiastype {
    describe('inprotech.configuration.general.names.namealiastype.NameAliasTypeService', () => {
        'use strict';

        let service: INameAliasTypeService, httpMock: any;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.names.namealiastype');

            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);

                httpMock = $injector.get('httpMock');
                $provide.value('$http', httpMock);
            });
        });

        beforeEach(inject((NameAliasTypeService: INameAliasTypeService) => {
            service = NameAliasTypeService;
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

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/names/aliastype/search', {
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

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/names/aliastype/search', {
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

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/names/aliastype/search', {
                    params: {
                        q: JSON.stringify(criteria),
                        params: JSON.stringify(queryParams)
                    }
                });
            });
        });
        it('get should make backend call to fetch the record', () => {
            service.get(1);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/names/aliastype/1');
        });
        it('add should make backend call for post', () => {
            let entity: any = {
                id: 1,
                code: 'a',
                description: 'aaa',
                state: 'adding',
                saved: false
            };
            service.add(entity);

            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/names/aliastype/', entity);
        });
        it('update should make backend call for post', () => {
            let entity: any = {
                id: 1,
                code: 'a',
                description: 'aaa',
                state: 'updating',
                saved: false
            };
            service.update(entity);

            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/names/aliastype/' + entity.id, entity);
        });
        it('persistSavedNameAliasTypes should set saved property to true', () => {
            let searchResults = [{
                id: 1,
                code: '1',
                saved: false
            }, {
                id: 2,
                code: '2',
                saved: false
            }, {
                id: 3,
                code: '3',
                saved: false
            }];

            service.savedNameAliasTypeIds = ['1', '3'];

            service.persistSavedNameAliasTypes(searchResults);
            expect(searchResults[0].saved).toBe(true);
            expect(searchResults[2].saved).toBe(true);
        });
        it('delete should make http post backend call with ids', () => {
            let selectedItems = [{
                id: 1,
                code: 'aa',
                description: 'aaa',
                state: 'adding',
                saved: false
            }, {
                id: 2,
                code: 'bb',
                description: 'bbb',
                state: 'adding',
                saved: false
            }];

            service.deleteSelected(selectedItems);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/names/aliastype/delete', {
                ids: [1, 2]
            });
        });
        it('markInUseNameTypeAlias should mark name alias type with truthy inUse value', () => {
            let nameAliasType = [{
                id: 1,
                code: 'a',
                inUse: false
            }, {
                id: 2,
                code: 'b',
                inUse: false
            }, {
                id: 3,
                code: 'c',
                inUse: false
            }];

            let inUseIds = [1, 2];
            service.markInUseNameTypeAlias(nameAliasType, inUseIds);
            expect(nameAliasType[0].inUse).toBeTruthy();
            expect(nameAliasType[1].inUse).toBeTruthy();
            expect(nameAliasType[2].inUse).toBeFalsy();
        });
    });
}
