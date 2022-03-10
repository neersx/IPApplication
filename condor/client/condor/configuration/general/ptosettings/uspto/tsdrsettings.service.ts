'use strict';

interface ITsdrSettingsService {
    save(TsdrSettingModel): Promise<boolean>;
    test(TsdrSettingModel): Promise<boolean>;
}

class TsdrSettingsService implements ITsdrSettingsService {
    static $inject = ['$http'];

    constructor(private $http) {
    }

    save = (keys: TsdrSettingModel): Promise<boolean> => {
        return this.$http.post('api/configuration/ptosettings/uspto-tsdr', JSON.stringify(keys)
        ).then(function (response) {
            return response.data.result.status === 'success';
        });
    }

    test = (keys: TsdrSettingModel): Promise<boolean> => {
        return this.$http.put('api/configuration/ptosettings/uspto-tsdr', JSON.stringify(keys)
        ).then(function (response) {
            return response.data.result.status === 'success';
        });
    }
}
angular.module('inprotech.configuration.general.ptosettings.uspto')
    .service('TsdrSettingsService', TsdrSettingsService);
