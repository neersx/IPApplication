namespace inprotech.configuration.search {
    export interface IConfigurationsService {
        updated: number[];
        search(criteria, queryParams): any;
        update(entity: ConfigurationItemModel): any;
    }

    class ConfigurationsService implements IConfigurationsService {
        static $inject = ['$http'];

        updated: number[];

        constructor(private $http) {
            this.updated = [];
        }

        search(criteria, queryParams) {
            let q = this.buildQuery(criteria);

            return this.$http.get('api/configuration/search', {
                params: {
                    q: JSON.stringify(q),
                    params: JSON.stringify(queryParams)
                }
            }).then((response) => {
                _.each((response.data || {
                    data: []
                }).data, (item: ConfigurationItemModel) => {
                    _.each(this.updated, (updatedId: number) => {
                        if (item.id === updatedId || _.any(item.ids || [], (id: number) => id === updatedId)) {
                            item.saved = true;
                        }
                    });
                });
                return response.data;
            });
        }

        update = (entity: ConfigurationItemModel): any => {
            let updateEntity = new ConfigurationItemModel();
            updateEntity.groupId = entity.groupId;
            updateEntity.id = entity.id;
            updateEntity.ids = entity.ids;
            updateEntity.tags = _.map(entity.tags || [], (tag: Tags) => {
                let t = new Tags();
                t.id = tag.id || tag.key;
                t.key = tag.id || tag.key;
                t.tagName = tag.tagName;
                return t;
            });

            return this.$http.put('api/configuration/item', updateEntity)
                .then((response) => {
                    _.each(response, (cid: number) => {
                        this.updated.push(cid);
                    });
                });
        }

        buildQuery(criteria) {
            return {
                text: criteria.text || '',
                componentIds: _.map(criteria.components || [], (a: any) => a.id),
                tagIds: _.map(criteria.tags || [], (a: any) => a.key)
            };
        }
    }

    angular.module('inprotech.configuration.search')
        .service('ConfigurationsService', ConfigurationsService);
}