angular.module('inprotech.dev')
    .directive('devTypeaheadDynamicPresenter',
        function ($compile) {
            'use strict';
            return {
                restrict: 'E',
                scope: {
                    config: '=',
                    label: '='
                },
                template: '<div class="dynamic-placeholder"/>',
                link: function (scope, element) {
                    scope.$watch('config', function () {

                        scope.model = null;

                        element.find('.dynamic-placeholder').empty();

                        if (!scope.config) {
                            return;
                        }

                        var typeahead = $('<h2>' + scope.label + '</h2><div class="row">' +
                            '<ip-typeahead class="col-sm-6" data-config="' + scope.config + '" ng-model="scope.model" data-picklist-can-maintain="true"></ip-typeahead>' +
                            '<div class="col-sm-6"><div>model: {{scope.model | json}}</div></div></div>');
                        element.find('.dynamic-placeholder').append(typeahead);
                        $compile(typeahead)(scope);
                    });
                }
            }
        })
    .controller('DevTypeaheadController',
        function ($translate, typeaheadConfig) {
            'use strict';

            var vm = this;

            vm.$onInit = onInit;

            function onInit() {

                vm.countries = [{
                    id: 'AU',
                    description: 'Australia'
                }];

                vm.country = {
                    id: 'AU',
                    description: 'Australia'
                };

                vm.customPicklistModal = {
                    list: [{
                        id: '2',
                        value: 'Filter by 2'
                    }, {
                        id: '1',
                        value: 'Filter by 1'
                    }],
                    extendQuery: function (query) {
                        var extended = angular.extend({}, query, {
                            customParam: vm.customPicklistModal.selectedItem,
                            latency: 888
                        });

                        vm.customPicklistModal.outgoingRequest = extended;
                        return extended;
                    }
                };

                vm.workflowDocs = {
                    legacy: true,
                    extendQuery: function (query) {
                        var extended = angular.extend({}, query, {
                            compatibility: {
                                legacy: vm.workflowDocs.legacy
                            },
                            latency: 888
                        });

                        vm.workflowDocs.outgoingRequest = extended;
                        return extended;
                    }
                };

                vm.designationStage = {
                    jurisdictionId: 'PCT',
                    externalScope: function () {
                        return {
                            jurisdiction: 'Patent Corporation Treaty'
                        };
                    },
                    extendQuery: function (query) {
                        var extended = angular.extend({}, query, {
                            jurisdictionId: vm.designationStage.jurisdictionId,
                            latency: 888
                        });

                        vm.designationStage.outgoingRequest = extended;
                        return extended;
                    }
                };

                vm.textType = {
                    caseOnly: true,
                    extendQuery: function (query) {
                        var extended = angular.extend({}, query, {
                            mode: vm.textType.caseOnly ? "case" : "all",
                            latency: 888
                        });

                        vm.textType.outgoingRequest = extended;
                        return extended;
                    }
                };

                vm.availableConfigs = _.map(typeaheadConfig.$reveal(), function (item) {
                    var resolved = typeaheadConfig.resolve({
                        config: item
                    });
                    return {
                        config: item,
                        label: $translate.instant(resolved.label) + ' Pick List'
                    };
                });

                vm.selectedConfig = {};
            }

            vm.extendJurisdictionPicklist = function extendJurisdictionPicklist(query) {

                var extended = angular.extend({}, query, {
                    isGroup: true,
                    excludeCountry: 'OA',
                    latency: 888
                });
                return extended;
            };

            vm.extendWipTemplatePicklist = function extendWipTemplatePicklist(query) {
                return angular.extend({}, query, {
                    caseId: vm.wipTemplateCase.key
                });
            };
        });