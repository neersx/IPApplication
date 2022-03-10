module inprotech.names.consolidation {
    'use strict';

    export interface INamesConsolidationService {
        consolidate(targetNameNo: number, ignoreTypeWarnings: boolean, ignoreFinancialWarnings: boolean, KeepAddressHistory: boolean, KeepTelecomHistory: boolean, namesToBeConsolidated: number[]): ng.IPromise<any>;
    }

    class NamesConsolidationService implements INamesConsolidationService {
        static $inject: string[] = ['$http'];
        constructor(private $http: angular.IHttpService) { }

        consolidate(targetNameNo: number, ignoreTypeWarnings: boolean, ignoreFinancialWarnings: boolean, keepAddressHistory: boolean, keepTelecomHistory: boolean, namesToBeConsolidated: number[]): ng.IPromise<any> {
            return this.$http.post('api/names/consolidate/' + encodeURI(targetNameNo.toString()), {
                ignoreTypeWarnings,
                ignoreFinancialWarnings,
                namesToBeConsolidated,
                keepAddressHistory,
                keepTelecomHistory
            }).then(response => response.data);
        }
    }

    angular.module('inprotech.names.consolidation')
        .service('NamesConsolidationService', NamesConsolidationService);
}
