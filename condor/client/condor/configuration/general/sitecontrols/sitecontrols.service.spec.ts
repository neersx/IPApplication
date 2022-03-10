namespace inprotech.configuration.general.sitecontrols {
    describe('inprotech.configuration.general.sitecontrols.SiteControlService', () => {
        'use strict';

        let service: ISiteControlService, httpMock: any;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.sitecontrols');
            angular.mock.module(($provide) => {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);

                httpMock = $injector.get('httpMock');
                $provide.value('$http', httpMock);
            });
        });

        beforeEach(inject((SiteControlService: ISiteControlService) => {
            service = SiteControlService;
        }));

        describe('searching', () => {
            it('should pass correct parameters', () => {
                let criteria = {
                    isByName: true,
                    isByDescription: true,
                    isByValue: true,
                    text: 'text',
                    release: {
                        id: 'vid'
                    },
                    components: [{
                        id: 'cid'
                    }],
                    tags: [{
                        key: 'tid'
                    }]
                };

                let query = {
                    isByName: true,
                    isByDescription: true,
                    isByValue: true,
                    text: 'text',
                    versionId: 'vid',
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

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/sitecontrols', {
                    params: {
                        q: JSON.stringify(query),
                        params: JSON.stringify(queryParams)
                    }
                });
            });
            it('should accept empty criteria', () => {
                let criteria = {};
                let query = {
                    isByName: false,
                    isByDescription: false,
                    isByValue: false,
                    text: '',
                    versionId: null,
                    componentIds: [],
                    tagIds: []
                };

                service.search(criteria, undefined);

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/sitecontrols', {
                    params: {
                        q: JSON.stringify(query),
                        params: undefined
                    }
                });
            });
        });

        describe('loading sitecontrol details', () => {
            beforeEach(() => {
                httpMock.get.returnValue = {
                    id: 1,
                    name: 'a'
                };

                service.get(1);
            });
            it('should fetch new sitecontrol and attach to context', () => {
                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/sitecontrols/1');
            });
            it('should attach to context', () => {
                expect(service.find(1)).toBeDefined();
            });
            it('should return existing sitecontrol', () => {
                // call again
                service.get(1);

                expect(httpMock.get.calls.count()).toBe(1);
            });
        });

        describe('saving', () => {
            it('should pass correct parameters', () => {
                httpMock.get.returnValue = {
                    id: 1,
                    value: 'a',
                    notes: 'n',
                    tags: 't'
                };

                let extObj = service.get(1);
                extObj.value = 'b';

                service.save();
                expect(httpMock.put).toHaveBeenCalledWith('api/configuration/sitecontrols', [{
                    id: 1,
                    value: 'b',
                    notes: 'n',
                    tags: 't'
                }]);

                expect(extObj.isSaved()).toBe(true);
            });
        });
    });
}
