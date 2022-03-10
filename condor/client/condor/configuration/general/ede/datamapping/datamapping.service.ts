namespace inprotech.configuration.general.ede.datamapping {
    export interface IDataMappingService {
        get(datasource: string, id: number): any;
        search(dataSource, structure, queryParams): any;
        add(entity): any;
        update(entity): any;
        deleteSelected(items): any;
    }

    export class DataMappingService implements IDataMappingService {

        static $inject = ['$http'];
        baseUrl: String = 'api/configuration/ede/datamapping/';

        constructor(private $http) {
        }

        get = (datasource: string, id: number) => {
            return this.$http.get(this.baseUrl + 'datasource/' + datasource + '/mapping/' + id).then(response => response.data);
        }

        search = (dataSource: string, structure: string, queryParams: any) => {
            return this.$http.get(this.baseUrl + 'datasource/' + dataSource + '/structure/' + structure + '/mappings', {
                params: {
                    params: JSON.stringify(queryParams)
                }
            }).then(response => response.data);
        }

        add = (entity) => {
            return this.$http.post(this.baseUrl, entity);
        }

        update = (entity) => {
            return this.$http.put(this.baseUrl + entity.mapping.id, entity);
        }

        deleteSelected = (items) => {
            return this.$http.post(this.baseUrl + 'delete', {
                ids: _.pluck(items, 'id')
            })
        }
    }

    angular.module('inprotech.configuration.general.ede.datamapping')
        .service('DataMappingService', DataMappingService);
}