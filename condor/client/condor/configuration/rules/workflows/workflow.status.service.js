angular.module('inprotech.configuration.rules.workflows').factory('workflowStatusService', function($http, validCombinationService) {
    'use strict';

    var validCharacteristics = {};
    var caseStatusParam = {
        'isRenewal': false
    };
    var renewalStatusParam = {
        'isRenewal': true
    };

    function init(characteristics) {
        setValidCharacteristics(characteristics);

        return {
            caseStatusQuery: caseStatusQuery,
            renewalStatusQuery: renewalStatusQuery,
            validStatusQuery: validStatusQuery,
            validCombination: getValidCombination(characteristics),
            allCaseStatusQuery: allCaseStatusQuery,
            allRenewalStatusQuery: allRenewalStatusQuery,
            allValidStatusQuery: allValidStatusQuery,
            isStatusValid: isStatusValid,
            addValidStatus: addValidStatus
        };
    }
    return init;

    function validStatusQuery(query) {
        return angular.extend({}, query, validCharacteristics);
    }

    function allValidStatusQuery(query) {
        return angular.extend({}, query, {});
    }

    function caseStatusQuery(query) {
        return angular.extend({}, query, caseStatusParam, validCharacteristics);
    }

    function renewalStatusQuery(query) {
        var obj = angular.extend({}, query, renewalStatusParam, validCharacteristics);
        return obj;
    }

    function allCaseStatusQuery(query) {
        return angular.extend({}, query, caseStatusParam, {});
    }

    function allRenewalStatusQuery(query) {
        return angular.extend({}, query, renewalStatusParam, {});
    }

    function keyOrNull(o) {
        return o == null ? null : o.key;
    }

    function setValidCharacteristics(characteristics) {
        validCharacteristics = {
            caseType: keyOrNull(characteristics.caseType),
            jurisdiction: keyOrNull(characteristics.jurisdiction),
            propertyType: keyOrNull(characteristics.propertyType)
        }
    }

    function getValidCombination(characteristics) {
        var validDescriptions = {
            combination: function() {
                return _.without(_.pluck(characteristics, 'value'), undefined);
            }
        };

        return validDescriptions.combination().length === 3 ? validDescriptions : null;
    }

    function isStatusValid(id, isRenewal) {
        return $http.get('api/picklists/status/isvalid/' + encodeURIComponent(id), {
                params: angular.extend({}, validCharacteristics, {
                    isRenewal: isRenewal
                })
            })
            .then(function(response) {
                return response.data.result;
            });
    }

    function addValidStatus(entity, characteristics, isDefaultCountry) {
        validCombinationService.add({
            Status: entity,
            CaseType: {
                Code: keyOrNull(characteristics.caseType),
                Key: keyOrNull(characteristics.caseType)
            },
            Jurisdictions: [{
                Code: isDefaultCountry ? 'ZZZ' : keyOrNull(characteristics.jurisdiction),
                Key: isDefaultCountry ? 'ZZZ' : keyOrNull(characteristics.jurisdiction)
            }],
            PropertyType: {
                Code: keyOrNull(characteristics.propertyType),
                Key: keyOrNull(characteristics.propertyType)
            }
        }, {
            type: 'status'
        });
    }
});