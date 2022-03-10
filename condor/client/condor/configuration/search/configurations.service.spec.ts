namespace inprotech.configuration.search {
    describe('inprotech.configuration.search.ConfigurationsService', () => {
        'use strict';

        let service: IConfigurationsService, httpMock: any;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.search');
            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);

                httpMock = $injector.get('httpMock');
                $provide.value('$http', httpMock);
            });
        });

        beforeEach(inject((ConfigurationsService: IConfigurationsService) => {
            service = ConfigurationsService;
        }));

        describe('searching', () => {
            it('should pass correct parameters', () => {
                let criteria = {
                    text: 'text',
                    components: [{
                        id: 'cid'
                    }],
                    tags: [{
                        key: 'tid'
                    }]
                };

                let query = {
                    text: 'text',
                    componentIds: ['cid'],
                    tagIds: ['tid']
                };

                let queryParams = {
                    sortBy: 'id',
                    sortDir: 'asc',
                    skip: 1,
                    take: 2
                };

                service.search(criteria, queryParams);

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/search', {
                    params: {
                        q: JSON.stringify(query),
                        params: JSON.stringify(queryParams)
                    }
                });
            });

            it('should accept empty criteria', () => {
                let criteria = {};
                let query = {
                    text: '',
                    componentIds: [],
                    tagIds: []
                };

                service.search(criteria, undefined);

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/search', {
                    params: {
                        q: JSON.stringify(query),
                        params: undefined
                    }
                });
            });
        });

        describe('saving', () => {
            it('should call put the save', () => {
                let item = {
                    id: 1,
                    tags: []
                };

                httpMock.get.returnValue = {
                    data: [item, {
                        id: 2,
                        tags: [{
                            key: 123,
                            tagName: 'xyz'
                        }]
                    }]
                }

                let entity = new ConfigurationItemModel();
                let tagUpdated = new Tags();
                tagUpdated.id = 1;
                tagUpdated.key = 1;
                tagUpdated.tagName = 'test';

                entity.id = 1;
                entity.tags = [tagUpdated];

                service.update(entity);

                expect(httpMock.put).toHaveBeenCalledWith('api/configuration/item', jasmine.objectContaining(_.extend({
                    id: 1
                }, {
                    tags: [tagUpdated]
                })));
            });
        });
    });
}