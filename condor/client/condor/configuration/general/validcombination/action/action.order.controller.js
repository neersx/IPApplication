angular.module('inprotech.configuration.general.validcombination')
    .controller('ActionOrderController', ActionOrderController);


function ActionOrderController(kendoGridBuilder, $scope, validCombinationService, options, notificationService, hotkeys, modalService, utils, $timeout) {
    'use strict';

    var ctrl = this;

    ctrl.dismiss = dismiss;
    ctrl.save = save;
    ctrl.onFilterCriteriaChanged = doSearch;
    ctrl.hint = 'validcombinations.actionSearchHint';
    ctrl.displayNoItems = false;
    ctrl.gridOptions = buildGridOptions();
    ctrl.moveUp = moveRowUp;
    ctrl.moveDown = moveRowDown;
    ctrl.disableUpButton = true;
    ctrl.disableDownButton = true;
    ctrl.hasChanges = false;
    ctrl.setHeader = setHeader;
    ctrl.navigate = navigate;
    ctrl.initShortcuts = initShortcutsactionOrder;

    _.extend(ctrl, {
        currentItem: options.dataItem,
        allItems: options.allItems,
        hasUnsavedChanges: hasUnsavedChanges,
        launchSrc: options.launchSrc
    });

    initialize();
    $timeout(initShortcutsactionOrder, 500);

    function initialize() {
        ctrl.filterCriteria = {
            jurisdiction: angular.equals(options.dataItem.jurisdiction, undefined) ? {} : picklistModel(options.dataItem.jurisdiction),
            propertyType: angular.equals(options.dataItem.propertyType, undefined) ? {} : picklistModel(options.dataItem.propertyType),
            caseType: angular.equals(options.dataItem.caseType, undefined) ? {} : picklistModel(options.dataItem.caseType)
        };
        ctrl.picklistErrors = {};
    }

    function initShortcutsactionOrder() {
        hotkeys.add({
            combo: 'alt+shift+up',
            description: 'shortcuts.actionOrderRow.moveUp',
            callback: function() {
                if (!ctrl.disableUpButton && modalService.isOpen('ActionOrder')) {
                    ctrl.moveUp();
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+down',
            description: 'shortcuts.actionOrderRow.moveDown',
            callback: function() {
                if (!ctrl.disableDownButton && modalService.isOpen('ActionOrder')) {
                    ctrl.moveDown();
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: function() {
                if (ctrl.hasChanges && modalService.isOpen('ActionOrder')) {
                    ctrl.save();
                }
            }
        });

        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.revert',
            callback: function() {
                if (modalService.isOpen('ActionOrder')) {
                    ctrl.dismiss();
                }
            }
        });
    }

    function picklistModel(model) {
        return {
            key: model.key,
            value: model.value,
            code: model.code
        };
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'validActionResults',
            scrollable: false,
            reorderable: false,
            autoGenerateRowTemplate: true,
            rowAttributes: 'ng-class="{saved: dataItem.saved}"',
            serverFiltering: false,
            selectable: 'single, row',
            dragDropRows: true,
            change: function(e) {
                var grid = e.sender;
                ctrl.selectedDataItem = grid.dataItem(this.select());
                var index = grid.dataSource.indexOf(ctrl.selectedDataItem);
                var maxIndex = grid.dataSource._data.length - 1;
                updateUpDownButtonState(index, maxIndex);
                utils.safeApply($scope);
            },
            dataBound: function(e) {
                selectRow(e);
                adjustScrollHeight();
            },
            autoBind: true,
            read: doSearch,
            onDropCompleted: function(e) {
                ctrl.selectedDataItem = e.selectedDataItem;
                ctrl.hasChanges = e.hasSelectedRowChanges;
                selectRow(e);
                updateUpDownButtonState(e.currentTarget, e.maxIndex);
                utils.safeApply($scope);
            },
            columns: [{
                title: 'Code',
                field: 'code',
                width: '10%',
                sortable: false,
                oneTimeBinding: true
            }, {
                title: 'Description',
                field: 'description',
                width: '20%',
                sortable: false,
                oneTimeBinding: true
            }, {
                title: 'Cycles',
                field: 'cycles',
                width: '15%',
                sortable: false,
                oneTimeBinding: true
            }, {
                title: 'Renewal',
                template: '<input type="checkbox" ng-model="dataItem.renewal" disabled="disabled"></input>',
                width: '15%',
                sortable: false
            }, {
                title: 'Examination',
                template: '<input type="checkbox" ng-model="dataItem.examination" disabled="disabled"></input>',
                width: '15%',
                sortable: false
            }]
        });
    }

    function selectRow(e) {
        var grid = e.sender;
        grid.items().each(function(idx, item) {
            var dataItem = grid.dataItem(item);
            if (dataItem === ctrl.selectedDataItem) {
                e.sender.select(item);
                var row = e.sender.tbody.find("[data-uid='" + dataItem.uid + "']");
                row.addClass('k-state-selected');
                adjustScrollHeight(item);
                return true;
            }
        });
    }

    function adjustScrollHeight(selectedRow) {
        if (!angular.isDefined(selectedRow) && ctrl.launchSrc !== 'maintenance') return;
        var div = $('#modal-content');
        var top = selectedRow ? selectedRow.offsetTop : div.position().top;
        var height = selectedRow ? selectedRow.offsetHeight : div.height();
        div.scrollTop(top + height);
    }


    $scope.$watch(angular.bind(ctrl, function() {
        return ctrl.disableUpButton;
    }), function(newVal) {
        ctrl.disableUpButton = newVal;
    });

    $scope.$watch(angular.bind(ctrl, function() {
        return ctrl.disableDownButton;
    }), function(newVal) {
        ctrl.disableDownButton = newVal;
    });

    function doSearch() {
        if (eligibleForSearch()) {
            var query = buildQuery(ctrl.filterCriteria);
            validCombinationService.validActions('action', query).then(function(response) {
                ctrl.actionOrderCriteria = response.data.orderCriteria;
                setSaved(response.data.validActions);
                ctrl.gridOptions.dataSource.data(response.data.validActions);
                evaluateHint();
            });
        } else {
            ctrl.hint = 'validcombinations.actionSearchHint';
            ctrl.displayNoItems = false;
            if (ctrl.gridOptions.data() && ctrl.gridOptions.data().length > 0) {
                ctrl.gridOptions.clear();
            }
            ctrl.disableUpButton = true;
            ctrl.disableDownButton = true;
        }
        ctrl.hasChanges = false;
    }

    function setHeader() {
        ctrl.currentItem.jurisdiction = ctrl.filterCriteria.jurisdiction;
        ctrl.currentItem.propertyType = ctrl.filterCriteria.propertyType;
        ctrl.currentItem.caseType = ctrl.filterCriteria.caseType;
    }

    function setSaved(data) {
        if (ctrl.launchSrc !== 'maintenance') {
            return;
        }

        var savedEntityId = {
            countryId: ctrl.filterCriteria.jurisdiction.code,
            actionId: options.action.code,
            propertyTypeId: ctrl.filterCriteria.propertyType.code,
            caseTypeId: ctrl.filterCriteria.caseType.code
        };

        _.each(data, function(item) {
            if (JSON.stringify(savedEntityId) === JSON.stringify(item.id)) {
                item.saved = true;
            }
        });
    }

    function evaluateHint() {
        if (ctrl.gridOptions.data().length > 1) {
            ctrl.displayNoItems = false;
            ctrl.hint = 'validcombinations.actionOrderHint';
        } else {
            ctrl.hint = '';
            if (ctrl.gridOptions.data().length === 0) {
                ctrl.displayNoItems = true;
            }
        }
    }

    function buildQuery(criteria) {
        return {
            propertyType: criteria.propertyType.code,
            jurisdiction: criteria.jurisdiction.key,
            caseType: criteria.caseType.code
        };
    }

    function eligibleForSearch() {
        if (isValidPicklistState(ctrl.filterCriteria.jurisdiction) && isValidPicklistState(ctrl.filterCriteria.propertyType) && isValidPicklistState(ctrl.filterCriteria.caseType)) {
            return true;
        }
        return false;
    }

    function isValidPicklistState(picklist) {
        return picklist !== null && angular.isDefined(picklist.key) && angular.isDefined(picklist.value);
    }

    function moveRowUp() {
        var grid = ctrl.gridOptions.$widget.element.data('kendoGrid');
        var dataItem = grid.dataItem(grid.select());
        if (dataItem) {
            var index = grid.dataSource.indexOf(dataItem);
            if (index > 0) {
                var newIndex = index - 1;
                grid.dataSource.remove(dataItem);
                grid.dataSource.insert(newIndex, dataItem);
                ctrl.hasChanges = true;
            }
        }
    }

    function moveRowDown() {
        var grid = ctrl.gridOptions.$widget.element.data('kendoGrid');
        var dataItem = grid.dataItem(grid.select());
        if (dataItem) {
            var index = grid.dataSource.indexOf(dataItem);
            var maxIndex = grid.dataSource._data.length - 1;
            if (index < maxIndex) {
                var newIndex = index + 1;
                grid.dataSource.remove(dataItem);
                grid.dataSource.insert(newIndex, dataItem);
                ctrl.hasChanges = true;
            }
        }
    }

    function dismiss() {
        if (ctrl.hasChanges) {
            notificationService.discard()
                .then(function() {
                    modalService.close('ActionOrder');
                });
        } else {
            modalService.close('ActionOrder');
        }
    }

    function updateUpDownButtonState(index, maxIndex) {
        if (index > 0 && index < maxIndex) {
            ctrl.disableUpButton = false;
            ctrl.disableDownButton = false;
        } else if (index === 0 && index < maxIndex) {
            ctrl.disableUpButton = true;
            ctrl.disableDownButton = false;
        } else if (index === maxIndex && maxIndex !== 0) {
            ctrl.disableUpButton = false;
            ctrl.disableDownButton = true;
        } else if (index === maxIndex) {
            ctrl.disableUpButton = true;
            ctrl.disableDownButton = true;
        }
    }

    function save() {
        var data = [];
        _.each(ctrl.gridOptions.data(), function(item, index) {
            item.displaySequence = index;
            data.push(item);
        });

        var saveDetail = {
            validActions: data,
            orderCriteria: ctrl.actionOrderCriteria
        };

        validCombinationService.updateActionSequence(saveDetail).then(function(response) {
            if (response.data.result.result === 'success') {
                notificationService.success();
                ctrl.selectedDataItem = null;
                ctrl.hasChanges = false;
                doSearch();
                updateUpDownButtonState(0, 0);
                if (ctrl.launchSrc === 'maintenance') {
                    navigate();
                }
            }
        }, function(response) {
            notificationService.alert({
                message: 'modal.alert.unsavedchanges',
                errors: _.where(response.data.errors, {
                    field: null
                })
            });
        });
    }

    function hasUnsavedChanges() {
        return ctrl.hasChanges;
    }

    function navigate() {
        var allItems = options.allItems;
        var currentItem = options.dataItem;
        var currentIndex = _.indexOf(allItems, currentItem);

        if (currentIndex < (options.allItems.length - 1)) {
            var newItem = ctrl.allItems[currentIndex + 1];
            $scope.$emit('modalChangeView', {
                dataItem: newItem
            });
        }
    }

}