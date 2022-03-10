(function () {
    'use strict';

    angular.module('inprotech.processing.policing')
        .controller('ipPolicingRequestLogerrordetailController', ipPolicingRequestLogerrordetailController);

    ipPolicingRequestLogerrordetailController.$inject = ['$scope', 'kendoGridBuilder', 'policingRequestLogService', 'modalService'];

    function ipPolicingRequestLogerrordetailController($scope, kendoGridBuilder, policingRequestLogService, modalService) {
        var vm = this;

        vm.combinedFieldTemplate = combinedFieldTemplate;
        $scope.policingRequestLogService = policingRequestLogService;

        $scope.errorDetailGridOptions = kendoGridBuilder.buildOptions($scope, {
            id: 'errordetail',
            filterOptions: {
                keepFiltersAfterRead: true,
                sendExplicitValues: true
            },
            'pageable': {
                pageSize: 10
            },
            scrollable: true,
            autoBind: true,
            reorderable: false,
            resizable: false,
            read: function (queryParams) {
                return policingRequestLogService.getErrors($scope.data.policingLogId, queryParams);
            },
            columns: getColumns(),
            navigatable: true,
            selectable: true,
            onSelect: function () {
                $scope.errorDetailGridOptions.clickHyperlinkedCell();
            }
        });

        function getColumns() {
            return [{
                title: 'policing.request.log.errors.internalReference',
                sortable: false,
                width: '100px',
                template: function (dataItem) {
                    return '<a href="../default.aspx?caseref=' + encodeURIComponent(dataItem.irn) + '" target="_blank" ng-class="pointerCursor">{{dataItem.irn}}</a>';
                }
            }, {
                title: 'policing.request.log.errors.message',
                field: 'message',
                sortable: false,
                width: '120px'
            }, {
                title: 'policing.request.log.errors.event',
                field: 'eventDescription',
                sortable: false,
                width: '120px',
                template: function (dataItem) {
                    if ($scope.policingRequestLogService.displayCriteriaLinks && dataItem.hasEventControl && dataItem.eventNo) {
                        return '<a href="#/configuration/rules/workflows/' + dataItem.criteriaNo + '/eventcontrol/' + dataItem.eventNo + '">{{ vm.combinedFieldTemplate(dataItem.eventDescription,dataItem.eventNo) }}</a>';
                    } else {
                        return '<span ng-if="dataItem.eventNo">{{ vm.combinedFieldTemplate(dataItem.eventDescription,dataItem.eventNo) }}</span>';
                    }
                }
            }, {
                title: 'policing.request.log.errors.cycleNo',
                field: 'cycleNo',
                sortable: false,
                width: '60px'
            }, {
                title: 'policing.request.log.errors.criteria',
                sortable: false,
                width: '120px',
                template: function (dataItem) {
                    if (dataItem.criteriaNo) {
                        if ($scope.policingRequestLogService.displayCriteriaLinks && dataItem.criteriaNo) {
                            return '<a href="#/configuration/rules/workflows/' + dataItem.criteriaNo + '">{{ vm.combinedFieldTemplate(dataItem.criteriaDescription,dataItem.criteriaNo) }}</a>';
                        } else {
                            return '<span ng-if="dataItem.criteriaNo>' + dataItem.criteriaNo + '</span>';
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

        $scope.dismissAll = function () {
            modalService.close('PolicingRequestLogErrors');
        };
    }
})();
