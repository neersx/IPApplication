angular.module('Inprotech.Integration.PtoAccess')
    .factory('dataSourceMap', ['url', function(url) {
        'use strict';

        var defaults = {
            caseSource: {
                partial: 'schedule-case-source.html'
            },
            downloadType: {
                partial: 'schedule-download-type.html'
            },
            list: {
                partial: 'schedule-item.html'
            },
            isContinuousAvailable: {
                partial: false
            }
        };

        var maps = [{
            name: 'UsptoPrivatePair',
            caseSource: {
                partial: null
            },
            downloadType: {
                partial: null
            },
            list: {
                partial: 'uspto/privatepair/schedule-item.html'
            },
            isContinuousAvailable: {
                partial: true
            }
        }, {
            name: 'UsptoTsdr',
            caseSource: {
                partial: defaults.caseSource.partial
            },
            downloadType: {
                partial: defaults.downloadType.partial,
                options: ['All', 'Documents']
            },
            list: {
                partial: defaults.list.partial
            },
            isContinuousAvailable: defaults.isContinuousAvailable
        }, {
            name: 'Epo',
            caseSource: {
                partial: defaults.caseSource.partial
            },
            downloadType: {
                partial: defaults.downloadType.partial,
                options: ['All', 'Documents']
            },
            list: {
                partial: defaults.list.partial
            },
            isContinuousAvailable: defaults.isContinuousAvailable
        }, {
            name: 'IpOneData',
            caseSource: {
                partial: defaults.caseSource.partial
            },
            downloadType: {
                partial: defaults.downloadType.partial,
                options: ['All', 'OngoingVerification']
            },
            list: {
                partial: defaults.list.partial
            },
            isContinuousAvailable: defaults.isContinuousAvailable
        }, {
            name: 'File',
            caseSource: {
                partial: defaults.caseSource.partial
            },
            downloadType: {
                partial: defaults.downloadType.partial,
                options: null
            },
            list: {
                partial: defaults.list.partial
            },
            isContinuousAvailable: defaults.isContinuousAvailable
        }];

        return {
            partial: function(dataSource, type) {
                if (!dataSource) {
                    return null;
                }

                var extended = _.find(maps, function(m) {
                    return m.name === dataSource;
                });

                var p = (extended || defaults)[type].partial;
                if (!p) {
                    return null;
                }

                return url.of('integration/ptoaccess/') + p;
            },
            downloadTypes: function(dataSource) {
                if (!dataSource) {
                    return null;
                }

                var extended = _.find(maps, function(m) {
                    return m.name === dataSource;
                });

                return (extended || defaults).downloadType.options;
            }
        };
    }]);