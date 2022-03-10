namespace inprotech.configuration.general.names.namerelations {
    export interface INameRelationService {
         savedIds: number[];
        search(criteria, queryParams): any;
        viewData(): any;
        add(entity): any;
        update(entity): any;
        get(id): any;
        deleteSelected(item): any;
        markInUseNameRelationship(dataset, inUseIds): any;
        persistSavedNameRelationship(dataset): any;
    }

    export interface INameRelation {
        id: any,
        inUse: boolean,
        selected: boolean,
        saved: boolean
    }

    export class NameRelationService implements INameRelationService {
        static $inject = ['$http'];
        savedIds: number[];
        baseUrl: String = 'api/configuration/names/namerelation/';

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

        markInUseNameRelationship = (dataset, inUseIds) => {
            _.each(dataset, (nameRelation: INameRelation) => {
                _.each(inUseIds, (inUseId) => {
                    if (nameRelation.id === inUseId) {
                        nameRelation.inUse = true;
                        nameRelation.selected = true;
                    }
                });
            });
        }

        persistSavedNameRelationship = (dataset) => {
            _.each(dataset, (nameRelation: INameRelation) => {
                _.each(this.savedIds, (savedId) => {
                    if (nameRelation.id === savedId) {
                        nameRelation.saved = true;
                    }
                });
            });
        }
    }

    angular.module('inprotech.configuration.general.names.namerelations')
        .service('NameRelationService', NameRelationService);
}