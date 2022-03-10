namespace inprotech.configuration.general.names.locality {
    export interface ILocalityService {
        savedIds: number[];
        search(criteria, queryParams): any;
        viewData(): any;
        add(entity): any;
        update(entity): any;
        get(id): any;
        deleteSelected(item): any;
        markInUseLocalities(dataset, inUseIds): any;
        persistSavedLocalities(dataset): any;
    }

    export interface ILocality {
        id: any,
        inUse: boolean,
        selected: boolean,
        saved: boolean
    }

    export class LocalityService implements ILocalityService {
        static $inject = ['$http'];
        savedIds: number[];
        baseUrl: String = 'api/configuration/names/locality/';

        constructor(private $http) {
            this.savedIds = [];
        }

        search = (criteria, queryParams) => {
            return this.$http.get(this.baseUrl + 'search', {
                params: {
                    q: JSON.stringify(criteria),
                    params: JSON.stringify(queryParams)
                }
            }).then((response) => {
                return response.data;
            });
        }

        viewData = () => {
            return this.$http.get(this.baseUrl + 'viewdata').then(function (response) {
                return response;
            });
        }

        get = (id) => {
            return this.$http.get(this.baseUrl + id).then(response => response.data);
        }

        deleteSelected = (item) => {
            return this.$http.post(this.baseUrl + 'delete', {
                ids: _.pluck(item, 'id')
            })
        }

        add = (entity) => {
            return this.$http.post(this.baseUrl, entity);
        }

        update = (entity) => {
            return this.$http.put(this.baseUrl + entity.id, entity);
        }

        markInUseLocalities = (dataset, inUseIds) => {
            _.each(dataset, (locality: ILocality) => {
                _.each(inUseIds, (inUseId) => {
                    if (locality.id === inUseId) {
                        locality.inUse = true;
                        locality.selected = true;
                    }
                });
            });
        }

        persistSavedLocalities = (dataset) => {
            _.each(dataset, (locality: ILocality) => {
                _.each(this.savedIds, (savedId) => {
                    if (locality.id === savedId) {
                        locality.saved = true;
                    }
                });
            });
        }
    }

    angular.module('inprotech.configuration.general.names.locality')
        .service('LocalityService', LocalityService);
}