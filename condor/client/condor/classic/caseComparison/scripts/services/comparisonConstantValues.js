angular.module('Inprotech.CaseDataComparison')
    .factory('comparisonConstantValues', function() {
        'use strict';
        return {
            dataSources: {
                UsptoPrivatePair: 'UsptoPrivatePair',
                UsptoTsdr: 'UsptoTsdr',
                Epo: 'Epo',
                IpOneData: 'IPOneData',
                File: 'File'
            },

            systemCodes: {
                UsptoPrivatePair: 'USPTO.PrivatePAIR',
                UsptoTsdr: 'USPTO.TSDR',
                Epo: 'EPO',
                IpOneData: 'IPOneData',
                File: 'FILE'
            }
        };
    });