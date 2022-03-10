angular.module('inprotech.configuration.general.validcombination')
    .factory('validCombinationConfirmationService', validCombinationConfirmationService);



function validCombinationConfirmationService(notificationService) {
    'use strict';
    var service = {
        confirm: confirm
    };

    function confirm(entity, response, callback) {

        var availableJurisdictions = angular.copy(entity.jurisdictions);
        _.each(response.countryKeys, function(countryKey) {
            availableJurisdictions = _.without(availableJurisdictions, _.findWhere(availableJurisdictions, {
                key: countryKey
            }));
        });

        var validCountries = _.pluck(availableJurisdictions, 'value');

        var options = {
            validationMessage: response.validationMessage,
            confirmationMessage: response.confirmationMessage,
            countries: response.countries,
            templateUrl: 'condor/configuration/general/validcombination/validcombination-confirmation.html',
            continue: 'modal.confirmation.save',
            cancel: 'modal.confirmation.cancel',
            validCountries: validCountries
        };

        notificationService.confirm(options).then(function() {
            entity.jurisdictions = angular.copy(availableJurisdictions);
            callback(entity);
        });

    }

    return service;

}
