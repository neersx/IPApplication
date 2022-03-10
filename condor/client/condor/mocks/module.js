window.test = (function() {
    'use strict';

    register([
        'inprotech.mocks',
        'inprotech.mocks.core',
        'inprotech.mocks.configuration.general.sitecontrols',
        'inprotech.mocks.configuration.general.standinginstructions',
        'inprotech.mocks.components.kendo',
        'inprotech.mocks.components.grid',
        'inprotech.mocks.components.tree',
        'inprotech.mocks.components.notification',
        'inprotech.mocks.components.picklist',
        'inprotech.mocks.configuration.rules.workflows',
        'inprotech.mocks.configuration.general.nametypes',
        'inprotech.mocks.configuration.general.texttypes',
        'inprotech.mocks.configuration.general.numbertypes',
        'inprotech.mocks.configuration.general.namerestrictions',
        'inprotech.mocks.configuration.general.status',
        'inprotech.mocks.configuration.validcombination',
        'inprotech.mocks.configuration.general.jurisdictions',
        'inprotech.mocks.components.barchart',
        'inprotech.mocks.processing.exchange',
        'inprotech.mocks.processing.policing',
        'inprotech.mocks.configuration.general.importancelevel',
        'inprotech.mocks.configuration.general.dataitem',
        'inprotech.mocks.search',
        'inprotech.mocks.configuration.general.dataitem',
        'inprotech.mocks.search.cases',
        'inprotech.mocks.configuration.general.names.locality',
        'inprotech.mocks.configuration.general.events.eventnotetypes',
        'inprotech.mocks.configuration.general.names.namealiastype',
        'inprotech.mocks.configuration.search',
        'inprotech.mocks.configuration.general.ede.datamapping',
        'inprotech.mocks.configuration.general.names.namerelations',
        'inprotech.mocks.portfolio.cases',
        'inprotech.mocks.bulkcaseimport',
        'inprotech.mocks.components.multistepsearch',
        'inprotech.mocks.components.savedsearchpanel',
        'inprotech.mocks.downgrades'
    ]);

    function register(namespaces) {
        namespaces.forEach(function(namespace) {
            angular.module(namespace, []);
        });

        angular.module('inprotech.mocks', namespaces);
    }

    return {
        mock: function(serviceName, mockName) {
            if (!mockName) {
                mockName = serviceName + 'Mock';
            }

            var provide;
            var $injector = angular.injector(['inprotech.mocks']);

            module(function($provide) {
                provide = $provide;
            });

            var instance = _.isObject(mockName) ? mockName : $injector.get(mockName);

            provide.value(serviceName, instance);

            return instance;
        },
        getMock: function(name) {
            var $injector = angular.injector(['inprotech.mocks']);
            return $injector.get(name);
        },
        spyOnAll: function(obj) {
            Object.keys(obj).forEach(function(key) {
                if (angular.isFunction(obj[key])) {
                    spyOn(obj, key).and.callThrough();
                }
            });

            return obj;
        }
    };
})();
