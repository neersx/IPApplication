angular.module('inprotech.configuration.rules.workflows').factory('characteristicsValidator', function($http, utils) {
    'use strict';

    var preRequest = utils.cancellable();
    var validate = _.debounce(function(criteria, callback) {
        preRequest.cancel();    

        return $http.get('api/configuration/rules/characteristics/validateCharacteristics', {
            params: {
                criteria: JSON.stringify(criteria),
                purposeCode: 'E'
            },
            timeout: preRequest.promise
        }).then(function(response) {
            return callback(response.data);
        });
    }, 100);

    return {
        validate: validate
    };
});
