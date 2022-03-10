'use strict';

interface IEpoSettingsService {
    save(EpoSettingModel): Promise<boolean>;
    test(EpoSettingModel): Promise<boolean>;
}

class EpoSettingsService implements IEpoSettingsService {
    static $inject = ['$http'];

    constructor(private $http) {
    }

    save = (keys: EpoSettingModel): Promise<boolean> => {
        return this.$http.post('api/configuration/ptosettings/epo', JSON.stringify(keys)
        ).then(function (response) {
            return response.data.result.status === 'success';
        });
    }

    test = (keys: EpoSettingModel): Promise<boolean> => {
        return this.$http.put('api/configuration/ptosettings/epo', JSON.stringify(keys)
        ).then(function (response) {
            return response.data.result.status === 'success';
        });
    }
}
angular.module('inprotech.configuration.general.ptosettings.epo')
    .service('EpoSettingsService', EpoSettingsService);
