angular.module('inprotech.configuration.general.ede.datamapping').directive('ipDatamappingStructure', () => {
    'use strict';
    return {
        restrict: 'E',
        controller: 'DataMappingStructureController',
        controllerAs: 'vm',
        templateUrl: 'condor/configuration/general/ede/datamapping/directives/datamapping.topic.html',
        bindToController: {
            topic: '='
        }
    };
});
