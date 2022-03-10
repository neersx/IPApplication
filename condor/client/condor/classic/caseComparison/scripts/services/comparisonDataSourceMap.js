angular.module('Inprotech.CaseDataComparison')
    .factory('comparisonDataSourceMap', ['comparisonConstantValues', '$translate', function(comparisonConstantValues, $translate) {
        'use strict';

        var maps = [{
            name: 'UsptoPrivatePair',
            docTemplate: 'condor/classic/caseComparison/doctemplates/uspto-private-pair-documents.html',
            language: false,
            showTooltipInScheduler: false,
            firstUseDate: false
        }, {
            name: 'UsptoTsdr',
            docTemplate: 'condor/classic/caseComparison/doctemplates/uspto-tsdr-documents.html',
            language: false,
            showTooltipInScheduler: false,
            firstUseDate: true
        }, {
            name: 'Epo',
            docTemplate: 'condor/classic/caseComparison/doctemplates/epo-documents.html',
            language: false,
            firstUseDate: false
        }, {
            name: 'IpOneData',
            language: true,
            showTooltipInScheduler: true,
            firstUseDate: false
        }];

        return {
            template: function(dataSource) {
                if (!dataSource) {
                    return null;
                }

                var template = _.find(maps, function(m) {
                    return m.name === dataSource;
                });

                return template ? template.docTemplate : null;
            },
            showLanguage: function(dataSource) {
                if (!dataSource) {
                    return false;
                }
                var source = _.find(maps, function(m) {
                    return m.name === dataSource;
                });
                return source ? source.language : false;
            },
            showFirstUseDate: function(dataSource) {
                if (!dataSource) {
                    return false;
                }
                var source = _.find(maps, function(m) {
                    return m.name === dataSource;
                });
                return source ? source.firstUseDate : false;
            },
            showTooltip: function(dataSource) {
                if (!dataSource) {
                    return false;
                }
                var source = _.find(maps, function(m) {
                    return m.name === dataSource;
                });
                return source ? source.showTooltipInScheduler : false;
            },
            systemCode: function(dataSource) {
                return comparisonConstantValues.systemCodes[dataSource];
            },
            name: function(dataSource) {
                return $translate.instant('caseComparison.gLblDS' + dataSource);
            }
        };
    }]);