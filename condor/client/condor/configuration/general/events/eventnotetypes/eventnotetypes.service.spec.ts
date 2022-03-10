namespace inprotech.configuration.general.events.eventnotetypes {
    describe('inprotech.configuration.general.events.eventnotetypes.EventNoteTypesService', () => {
        'use strict';

        let service: IEventNoteTypesService, httpMock: any;

        beforeEach(() => {
            angular.mock.module('inprotech.configuration.general.events.eventnotetypes');

            angular.mock.module(function ($provide) {
                let $injector: ng.auto.IInjectorService = angular.injector(['inprotech.mocks']);

                httpMock = $injector.get('httpMock');
                $provide.value('$http', httpMock);
            });
        });

        beforeEach(inject((EventNoteTypesService: IEventNoteTypesService) => {
            service = EventNoteTypesService;
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

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/events/eventnotetypes/search', {
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

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/events/eventnotetypes/search', {
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

                expect(httpMock.get).toHaveBeenCalledWith('api/configuration/events/eventnotetypes/search', {
                    params: {
                        q: JSON.stringify(criteria),
                        params: JSON.stringify(queryParams)
                    }
                });
            });
        });
        it('get should make backend call to fetch the record', () => {
            service.get(1);

            expect(httpMock.get).toHaveBeenCalledWith('api/configuration/events/eventnotetypes/1');
        });
        it('add should make backend call for post', () => {
            let entity: EventNoteTypeModel = {
                id: 1,
                description: 'aaa',
                sharingAllowed: true,
                isExternal: true,
                state: 'adding',
                saved: false
            };
            service.add(entity);

            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/events/eventnotetypes/', entity);
        });
        it('update should make backend call for post', () => {
            let entity: EventNoteTypeModel = {
                id: 1,
                description: 'aaa',
                sharingAllowed: true,
                isExternal: true,
                state: 'updating',
                saved: false
            };
            service.update(entity);

            expect(httpMock.put).toHaveBeenCalledWith('api/configuration/events/eventnotetypes/' + entity.id, entity);
        });
        it('persistSavedEventNoteTypes should set saved property to true', () => {
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

            service.savedEventNoteTypeIds = [1, 3];

            service.persistSavedEventNoteTypes(dataset);
            expect(dataset[0].saved).toBe(true);
            expect(dataset[2].saved).toBe(true);
        });
        it('delete should make http post backend call with ids', () => {
            let selectedItems = [{
                id: 1,
                description: 'aaa',
                sharingAllowed: true,
                isExternal: true,
                state: 'adding',
                saved: false
            }, {
                id: 2,
                description: 'bbb',
                sharingAllowed: true,
                isExternal: true,
                state: 'adding',
                saved: false
            }];

            service.deleteSelected(selectedItems);
            expect(httpMock.post).toHaveBeenCalledWith('api/configuration/events/eventnotetypes/delete', {
                ids: [1, 2]
            });
        });
        it('markInUseTextTypes should mark event note types with truthy inUse value', () => {
            let eventNoteTypes = [{
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
            service.markInUseEventNoteTypes(eventNoteTypes, inUseIds);
            expect(eventNoteTypes[0].inUse).toBeTruthy();
            expect(eventNoteTypes[1].inUse).toBeTruthy();
            expect(eventNoteTypes[2].inUse).toBeFalsy();
        });
    });
}
