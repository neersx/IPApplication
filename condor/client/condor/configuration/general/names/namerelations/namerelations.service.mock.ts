namespace inprotech.configuration.general.names.namerelations {
    class NameRelationServiceMock implements INameRelationService {

        public returnValues: any;
        public savedIds: any[];

        constructor() {
            this.returnValues = {};
            this.savedIds = [];
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
                    return cb(this.returnValues);
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

        persistSavedNameRelationship = () => {
            return angular.noop;
        }


        markInUseNameRelationship() {
            return angular.noop;
        }
    }
    angular.module('inprotech.mocks.configuration.general.names.namerelations')
        .service('NameRelationServiceMock', NameRelationServiceMock);
}
