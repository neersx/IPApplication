(function () {
    'use strict';

    angular.module('inprotech.processing.policing')
        .controller('ipPolicingRequestLogerrorController', ipPolicingRequestLogerrorController);

    ipPolicingRequestLogerrorController.$inject = ['$scope', 'kendoGridBuilder', 'modalService', 'policingRequestLogService'];

    function ipPolicingRequestLogerrorController($scope, kendoGridBuilder, modalService, policingRequestLogService) {
        var vm = this;
        vm.$onInit = onInit;

        function onInit() {
            vm.error = $scope.data.error;
            vm.service = policingRequestLogService;
            vm.combinedFieldTemplate = combinedFieldTemplate;

            vm.errorGridOptions = kendoGridBuilder.buildOptions($scope, {
                id: 'requestlogerror',
                filterOptions: {
                    keepFiltersAfterRead: true,
                    sendExplicitValues: true
                },
                pageable: false,
                scrollable: false,
                autoBind: true,
                reorderable: false,
                resizable: false,
                navigatable: true,
                selectable: true,
                onSelect: function () {
                    vm.errorGridOptions.clickHyperlinkedCell();
                },
                read: function () {
                    vm.totalErrorCount = vm.error.totalErrorItemsCount;
                    return vm.error.errorItems;
                },
                hideExpand: true,
                columns: getColumns()
            });
        }

        function getColumns() {
            return [{
                title: 'policing.request.log.errors.internalReference',
                sortable: false,
                width: '80px',
                template: function (dataItem) {
                    return '<a href="../default.aspx?caseref=' + encodeURIComponent(dataItem.irn) + '" target="_blank" ng-class="pointerCursor">{{dataItem.irn}}</a>';
                }
            }, {
                title: 'policing.request.log.errors.message',
                field: 'message',
                sortable: false,
                width: '150px'
            }, {
                title: 'policing.request.log.errors.event',
                sortable: false,
                width: '150px',
                template: function (dataItem) {
                    if (vm.service.displayCriteriaLinks && dataItem.hasEventControl && dataItem.eventNo) {
                        return '<a href="#/configuration/rules/workflows/' + dataItem.criteriaNo + '/eventcontrol/' + dataItem.eventNo + '">{{ vm.combinedFieldTemplate(dataItem.eventDescription,dataItem.eventNo) }}</a>';
                    } else {
                        return '<span ng-if="dataItem.eventNo">{{ vm.combinedFieldTemplate(dataItem.eventDescription,dataItem.eventNo) }}</span>';
                    }
                }
            }, {
                title: 'policing.request.log.errors.cycleNo',
                field: 'cycleNo',
                sortable: false,
                width: '30px'
            }, {
                title: 'policing.request.log.errors.criteria',
                sortable: false,
                width: '150px',
                template: function (dataItem) {
                    if (dataItem.criteriaNo) {
                        if (vm.service.displayCriteriaLinks) {
                            return '<a href="#/configuration/rules/workflows/' + dataItem.criteriaNo + '">{{ vm.combinedFieldTemplate(dataItem.criteriaDescription,dataItem.criteriaNo) }}</a>';
                        } else {
                            return '<span ng-if="dataItem.criteriaNo>{{dataItem.criteriaNo}}</span>';
                        }
                    } else return '';
                }
            }];
        }

        function combinedFieldTemplate(fieldValue, fieldInBrackets) {
            if (fieldValue && fieldInBrackets)
                return fieldValue + " (" + fieldInBrackets + ")";
            if (fieldValue)
                return fieldValue;
            if (fieldInBrackets)
                return fieldInBrackets
            return "";
        }

        vm.viewErrors = function () {
            modalService.open('PolicingRequestLogErrors', $scope);
        };
    }
})();
