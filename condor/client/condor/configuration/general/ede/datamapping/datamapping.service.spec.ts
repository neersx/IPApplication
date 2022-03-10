namespace inprotech.configuration.general.ede.datamapping {
    describe('inprotech.configuration.general.ede.datamapping', () => {
        'use strict';

        let service: IDataMappingService, httpMock: any;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.ede.datamapping');

            angular.mock.module(function ($provide) {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);

                httpMock = $injector.get('httpMock');
                $provide.value('$http', httpMock);
            });
        });

        beforeEach(inject((DataMappingService: IDataMappingService) => {
            service = DataMappingService;
        }));

        describe('searching', () => {
            it('should pass correct parameters', () => {
                let dataSource = 'epo',
                    structure = 'events',
                    queryParams = {
                        skip: 0,
                        take: 20
                    };

                service.search(dataSource, structure, queryParams);

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/ede/datamapping/datasource/epo/structure/events/mappings', {
                    params: {
                        params: JSON.stringify(queryParams)
                    }
                });
            });
        });
        it('get should make backend call to fetch the record', () => {
            let dataSource = 'epo',
                id = 1;

            service.get(dataSource, id);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/ede/datamapping/datasource/epo/mapping/1');
        });
        it('add should make backend call for post', () => {
            let entity = {
                mapping: {
                    id: null,
                    inputDesc: 'text',
                    event: {
                        key: 1,
                        code: 'AL',
                        description: 'Filing Event'
                    },
                    ignored: false
                }
            };

            service.add(entity);

            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/ede/datamapping/', entity);
        });
        it('update should make backend call for post', () => {
            let entity = {
                mapping: {
                    id: 1,
                    inputDesc: 'updated text',
                    event: {
                        key: 1,
                        code: 'AL',
                        description: 'Filing Event'
                    },
                    ignored: false
                }
            };

            service.update(entity);

            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/ede/datamapping/' + entity.mapping.id, entity);
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
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/ede/datamapping/delete', {
                ids: [1, 2]
            });
        });
    });
}
