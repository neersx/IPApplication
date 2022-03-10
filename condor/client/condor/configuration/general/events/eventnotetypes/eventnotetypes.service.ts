namespace inprotech.configuration.general.events.eventnotetypes {
    export interface IEventNoteTypesService {
        savedEventNoteTypeIds: number[];
        search(criteria, queryParams): any;
        viewData(): any,
        get(id: number): any;
        add(entity: EventNoteTypeModel): any;
        update(entity: EventNoteTypeModel): any;
        deleteSelected(item: EventNoteTypeModel[]): any;
        markInUseEventNoteTypes(resultSet: any, inUseIds: any): void;
        persistSavedEventNoteTypes(dataset: any): void;
    }

    export class EventNoteTypesService implements IEventNoteTypesService {

        static $inject = ['$http', 'ExtObjFactory'];

        public baseUrl: string;
        public searchResults: any;
        public savedEventNoteTypeIds: number[];

        constructor(private $http) {
            this.baseUrl = 'api/configuration/events/eventnotetypes/';
            this.savedEventNoteTypeIds = [];
        }

        search = (criteria, queryParams) => {
            return this.$http.get('api/configuration/events/eventnotetypes/search', {
                params: {
                    q: JSON.stringify(criteria),
                    params: JSON.stringify(queryParams)
                }
            }).then((response) => {
                return response.data;
            });
        }
        viewData = () => {
            return this.$http.get(this.baseUrl + 'viewdata').then((response) => {
                return response;
            });
        }

        deleteSelected = (items: EventNoteTypeModel[]): any => {
            return this.$http.post(this.baseUrl + 'delete', {
                ids: _.pluck(items, 'id')
            });
        }

        markInUseEventNoteTypes = (resultSet, inUseIds): void => {
            _.each(resultSet, (eventNoteType: any) => {
                _.each(inUseIds, (inUseId) => {
                    if (eventNoteType.id === inUseId) {
                        eventNoteType.inUse = true;
                        eventNoteType.selected = true;
                    }
                });
            });
        }

        find = (id: number): any => {
            return _.find(this.searchResults.data, (item: any) => {
                return item.id === id;
            });
        }

        get = (id: number): any => {
            return this.$http.get(this.baseUrl + id)
                .then((response) => {
                    return response.data;
                });
        }

        add = (entity: EventNoteTypeModel): any => {
            return this.$http.post(this.baseUrl, entity);
        }

        update = (entity: EventNoteTypeModel): any => {
            return this.$http.put(this.baseUrl + entity.id, entity);
        }

        persistSavedEventNoteTypes = (dataset): void => {
            _.each(dataset, (eventNoteType: EventNoteTypeModel) => {
                _.each(this.savedEventNoteTypeIds, (savedId: number) => {
                    if (eventNoteType.id === savedId) {
                        eventNoteType.saved = true;
                    }
                });
            });
        }

    }

    angular.module('inprotech.configuration.general.events.eventnotetypes')
        .service('EventNoteTypesService', EventNoteTypesService);
}
