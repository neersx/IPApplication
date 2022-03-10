namespace inprotech.configuration.general.events.eventnotetypes {
    class EventNoteTypesServiceMock implements IEventNoteTypesService {

        public searchResults: any;
        public savedEventNoteTypeIds: number[];

        constructor() {
            this.savedEventNoteTypeIds = [];
            spyOn(this, 'search').and.callThrough();
            spyOn(this, 'add').and.callThrough();
            spyOn(this, 'update').and.callThrough();
            spyOn(this, 'get').and.callThrough();
        }

        viewData = () => {
            return {
                then: (cb) => {
                    let response = { data: { result: {} } };
                    return cb(response);
                }
            }
        }

        search = () => {
            return {
                then: (cb) => {
                    return cb(this.searchResults);
                }
            };
        }

        get = (entityId) => {
            return {
                then: (cb) => {
                    return cb({ id: entityId, description: 'entity description' });
                }
            };
        }

        add = () => {
            return {
                then: (cb) => {
                    let response = { data: { result: {} } };
                    response.data.result = {
                        result: 'success',
                        updateId: 1
                    };
                    return cb(response);
                }
            };
        }

        update = () => {
            return {
                then: (cb) => {
                    let response = { data: { result: {} } };
                    response.data.result = {
                        result: 'success',
                        updateId: 1
                    };
                    return cb(response);
                }
            };
        }

        deleteSelected = () => {
            return {
                then: (cb) => {
                    return cb();
                }
            };
        }

        persistSavedEventNoteTypes = () => {
            return angular.noop;
        }

        markInUseEventNoteTypes = () => {
            return angular.noop;
        }
    }
    angular.module('inprotech.mocks.configuration.general.events.eventnotetypes')
        .service('EventNoteTypesServiceMock', EventNoteTypesServiceMock);
}
