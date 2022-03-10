namespace inprotech.configuration.general.names.namealiastype {
    class NameAliasTypeServiceMock implements INameAliasTypeService {

        public returnValues: any;
        public savedNameAliasTypeIds: any[];

        constructor() {
            this.savedNameAliasTypeIds = [];
            this.returnValues = {};
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

        persistSavedNameAliasTypes = () => {
            return angular.noop;
        }

        markInUseNameTypeAlias = () => {
            return angular.noop;
        }
    }
    angular.module('inprotech.mocks.configuration.general.names.namealiastype')
        .service('NameAliasTypeServiceMock', NameAliasTypeServiceMock);
}
