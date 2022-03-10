namespace inprotech.configuration.general.ede.datamapping {
    class DataMappingServiceMock implements IDataMappingService {

        public returnValues: any;
        public savedIds: any[];

        constructor() {
            this.returnValues = {};
            spyOn(this, 'search').and.callThrough();
            spyOn(this, 'add').and.callThrough();
            spyOn(this, 'update').and.callThrough();
            spyOn(this, 'get').and.callThrough();
        }

        search = () => {
            return {
                then: (cb) => {
                    return cb(this.returnValues);
                }
            };
        }

        get = (dataSource, id) => {
            return {
                then: (cb) => {
                    return cb({ id: id, description: 'input mapping description' });
                }
            };
        }

        add = () => {
            return {
                then: (cb) => {
                    let response = { data: { result: {} } };
                    response.data.result = {
                        result: 'success'
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
                        result: 'success'
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
    }

    angular.module('inprotech.mocks.configuration.general.ede.datamapping')
        .service('DataMappingServiceMock', DataMappingServiceMock);
}
