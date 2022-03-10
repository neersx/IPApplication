angular.module('Inprotech.Integration.ExternalApplication')
    .controller('externalApplicationTokenController', [
        '$scope', 'http', 'viewInitialiser', 'url', 'kendoGridBuilder', 'notificationService', 'modalService', '$state', '$translate',
        function ($scope, http, viewInitialiser, url, kendoGridBuilder, notificationService, modalService, $state, $translate) {
            'use strict';

            var vm = this;
            vm.$onInit = onInit;

            function onInit() {
                vm.externalApps = viewInitialiser.viewData.externalApps;
                vm.generateToken = generateToken;
                vm.editExternalApp = editExternalApp;
                vm.gridOptions = buildGridOptions();
            }

            function generateToken(id) {
                http.post(url.api('externalApplication/externalApplicationToken/generateToken?externalApplicationId=' + id))
                    .success(function (response) {
                        var data = response.viewData;
                        if (data.result === 'success') {
                            var app = _.find(vm.externalApps, function (obj) {
                                return obj.id === id;
                            });
                            if (app !== null) {
                                app.token = data.token;
                                app.isActive = data.isActive;
                                app.expiryDate = data.expiryDate;
                                vm.gridOptions.search();
                            }
                            notificationService.success();
                        } else {
                            notificationService.alert({
                                message: $translate.instant('externalApplication.failTokenGeneration')
                            });
                        }
                    });
            }

            var getApp = function (id) {
                return http.get(url.api('externalApplication/externalApplicationTokenEditView?id=' + id)).success(function (data) {
                    return data.viewData;
                });
            }

            function editExternalApp(id) {
                getApp(id).then(function (data) {
                    modalService.openModal({
                        id: 'ExternalApplicationEdit',
                        controllerAs: 'vm',
                        viewData: data
                    })
                        .then(function (result) {
                            if (result) {
                                $state.reload($state.current.name);
                            }
                        });
                });

            }

            function buildGridOptions() {
                return kendoGridBuilder.buildOptions($scope, {
                    id: 'searchResults',
                    scrollable: false,
                    reorderable: false,
                    navigatable: true,
                    serverFiltering: false,
                    autoBind: true,
                    read: function () {
                        return vm.externalApps;
                    },
                    columns: [{
                        title: $translate.instant('externalApplication.iealblTableTitle'),
                        sortable: false,
                        template: '<external-application-description model="dataItem"></external-application-description>'
                    }, {
                        sortable: false,
                        template: function (dataItem) {
                            var html = '<div class="pull-right"><button class="btn btn-prominent external-application-button" id="btnEdit_' + dataItem.id + '" ng-click="vm.editExternalApp(dataItem.id)" ng-show="dataItem.token != null">' + $translate.instant('externalApplication.ieabtnEdit') + '</button>';
                            html += '<button id="btnGenerateToken_' + dataItem.id + '" title="' + $translate.instant('externalApplication.tooltipGenerate') + '" ng-click="vm.generateToken(dataItem.id)" class="btn btn-prominent external-application-button">';
                            html += dataItem.token == null ? $translate.instant('externalApplication.ieabtnGenerateToken') : $translate.instant('externalApplication.ieabtnRegenerateToken');
                            html += '</button></div>';
                            return html;
                        }
                    }]
                });
            }
        }
    ]);