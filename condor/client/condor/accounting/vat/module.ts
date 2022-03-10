'use strict';
angular.module('inprotech.accounting.vat', [
        'inprotech.core',
        'inprotech.api',
        'inprotech.components'
    ])
    .config(function($stateProvider) {
        $stateProvider
            .state('vat', {
                url: '/accounting/vat',
                component: 'ipVat',
                resolve: {
                    viewData: function($http, $location) {
                        let stateId = $location.search().state;
                        $location.search('state', null);

                        return $http
                            .get('api/accounting/vat/view', {
                                params: {
                                    state: stateId
                                }
                            })
                            .then(response => {
                                return {
                                    entityNames: response.data.entityNames,
                                    stateId: response.data.stateId,
                                    deviceId: response.data.deviceId
                                };
                            });
                    }
                },
                data: {
                    pageTitle: 'accounting.vat.pageTitle'
                }
            })
            .state('hmrcsettings', {
                url: '/accounting/vat/settings',
                component: 'ipHmrcSettings',
                data: {
                    pageTitle: 'HMRC Settings'
                },
                resolve: {
                    viewData: function($http) {
                        return $http.get('api/accounting/vat/settings/view').then(function(response) {
                            return response.data;
                        });
                    }
                }
            });
    })