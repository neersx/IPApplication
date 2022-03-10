namespace inprotech.configuration.general.names.namealiastype {
    export interface INameAliasTypeService {
        savedNameAliasTypeIds: any [];
        search(criteria, queryParams): any;
        viewData(): any;
        add(entity): any;
        update(entity): any;
        get(id): any;
        deleteSelected(item): any;
        markInUseNameTypeAlias(resultSet, inUseIds): any;
        persistSavedNameAliasTypes(resultSet): any;
    }

    export interface INameAliasType {
        code: any;
        id: any,
        inUse: boolean,
        selected: boolean,
        saved: boolean
    }

   export class NameAliasTypeService implements INameAliasTypeService {
        static $inject = ['$http'];
        baseUrl: String = 'api/configuration/names/aliastype/';
        savedNameAliasTypeIds = [];

        constructor(private $http) {
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

        markInUseNameTypeAlias = (resultSet, inUseIds) => {
            _.each(resultSet, (nameTypeAlias: INameAliasType) => {
                _.each(inUseIds, (inUseId) => {
                    if (nameTypeAlias.id === inUseId) {
                        nameTypeAlias.inUse = true;
                        nameTypeAlias.selected = true;
                    }
                });
            });
        }

         persistSavedNameAliasTypes = (searchResults) => {
            _.each(searchResults, (nameTypeAlias: INameAliasType) => {
                _.each(this.savedNameAliasTypeIds, (savedNameAliasTypeId) => {
                    if (nameTypeAlias.code === savedNameAliasTypeId) {
                        nameTypeAlias.saved = true;
                    }
                });
            });
        }
    }

    angular.module('inprotech.configuration.general.names.namealiastype')
        .service('NameAliasTypeService', NameAliasTypeService);
}