namespace inprotech.configuration.general.sitecontrols {
    export interface ISiteControlService {
        search(criteria, queryParams): any;
        get(id): any;
        save(): any;
        isDirty(): boolean;
        discard();
        reset();
        find(id): any;
        hasError(): boolean;
        getInvalidSiteControls(): any;
    }

    class SiteControlService implements ISiteControlService {
        static $inject = ['$http', '$q', 'ExtObjFactory'];

        private state: any;

        constructor(private $http, private $q, private extObjFactory) {
            this.extObjFactory = new extObjFactory().useDefaults().use('observableArray');
            this.state = this.extObjFactory.createContext();
        }

        search(criteria, queryParams) {
            let q = this.buildQuery(criteria);

            return this.$http.get('api/configuration/sitecontrols', {
                params: {
                    q: JSON.stringify(q),
                    params: JSON.stringify(queryParams)
                }
            }).then(response => response.data);
        }
        get(id) {
            let found = this.state.find(id);

            if (found) {
                let deferred = this.$q.defer();
                deferred.resolve(found);
                return deferred.promise;
            }

            return this.$http.get('api/configuration/sitecontrols/' + id).then((response) => {
                let data = response.data;

                return this.state.attach(data);
            });
        }
        save() {
            let items = this.state.getDirtyItems();
            let newValues = items.map(a => ({
                id: a.id,
                value: a.value,
                notes: a.notes,
                tags: a.tags
            }));

            return this.$http.put('api/configuration/sitecontrols', newValues).then((response) => {
                this.state.save();

                return response.data;
            });
        }
        isDirty(): boolean {
            return this.state.isDirty();
        }
        discard() {
            this.state.restore();
        }
        reset() {
            this.state = this.extObjFactory.createContext();
        }
        find(id) {
            return this.state.find(id);
        }
        hasError(): boolean {
            return this.state.hasError();
        }
        getInvalidSiteControls() {
            return this.state.getInvalidItems().map(a => a.name);
        }

        buildQuery(criteria) {
            return {
                isByName: criteria.isByName || false,
                isByDescription: criteria.isByDescription || false,
                isByValue: criteria.isByValue || false,
                text: criteria.text || '',
                versionId: criteria.release ? criteria.release.id : null,
                componentIds: _.map(criteria.components || [], (a: any) => a.id),
                tagIds: _.map(criteria.tags || [], (a: any) => a.key)
            };
        }
    }

    angular.module('inprotech.configuration.general.sitecontrols')
        .service('SiteControlService', SiteControlService);
}
