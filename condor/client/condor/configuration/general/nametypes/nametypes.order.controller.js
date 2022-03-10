angular.module('inprotech.configuration.general.nametypes')
    .controller('NameTypesOrderController', NameTypesOrderController);

function NameTypesOrderController($uibModalInstance, kendoGridBuilder, $scope, nameTypesService, notificationService, hotkeys, modalService, utils, options, $timeout) {
    'use strict';

    var vm = this;
    vm.dismiss = dismiss;
    vm.save = save;
    vm.gridOptions = buildGridOptions();
    vm.moveUp = moveRowUp;
    vm.moveDown = moveRowDown;
    vm.disableUpButton = true;
    vm.search = doSearch;
    vm.disableDownButton = true;
    vm.hasChanges = false;
    vm.initShortcuts = initShortcutsNameTypesOrder;
    vm.updateUpDownButtonState = updateUpDownButtonState;
    initShortcutsNameTypesOrder();

    function initShortcutsNameTypesOrder() {
        hotkeys.add({
            combo: 'alt+shift+up',
            description: 'nameType.moveUp',
            callback: function () {
                if (!vm.disableUpButton && modalService.canOpen('NameTypesOrder')) {
                    vm.moveUp();
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+down',
            description: 'nameType.moveDown',
            callback: function () {
                if (!vm.disableDownButton && modalService.canOpen('NameTypesOrder')) {
                    vm.moveDown();
                }
            }
        });
        hotkeys.add({
            combo: 'alt+shift+s',
            description: 'shortcuts.save',
            callback: function () {
                if (vm.hasChanges && modalService.canOpen('NameTypesOrder')) {
                    vm.save();
                }
            }
        });

        hotkeys.add({
            combo: 'alt+shift+z',
            description: 'shortcuts.revert',
            callback: function () {
                if (modalService.canOpen('NameTypesOrder')) {
                    vm.dismiss();
                }
            }
        });
    }

    function buildGridOptions() {
        return kendoGridBuilder.buildOptions($scope, {
            id: 'validNameTypesResults',
            scrollable: false,
            reorderable: false,
            autoGenerateRowTemplate: true,
            rowAttributes: 'ng-class="{saved: dataItem.saved}"',
            serverFiltering: false,
            selectable: 'single, row',
            dragDropRows: true,
            change: function (e) {
                var grid = e.sender;
                vm.selectedDataItem = grid.dataItem(this.select());
                var index = grid.dataSource.indexOf(vm.selectedDataItem);
                var maxIndex = grid.dataSource._data.length - 1;
                updateUpDownButtonState(index, maxIndex);
                utils.safeApply($scope);
            },
            dataBound: function (e) {
                $timeout(selectRow, 1, true, e);
            },
            onDataCreated: function () {
                nameTypesService.persistSavedNameTypes(vm.gridOptions.data());
            },
            autoBind: true,
            read: doSearch,
            onDropCompleted: function (e) {
                vm.selectedDataItem = e.selectedDataItem;
                vm.hasChanges = e.hasSelectedRowChanges;
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
            }]
        });
    }

    function selectRow(e) {
        if (!angular.isObject(vm.selectedDataItem)) {
            if (options.launchSrc === 'maintenance') {
                var index = vm.gridOptions.data().length - 1;
                vm.gridOptions.selectRowByIndex(index)
                adjustScrollHeight(getSelectedRow(index));
            }
            return;
        }
        var grid = e.sender;
        grid.items().each(function (idx, item) {
            var dataItem = grid.dataItem(item);
            if (dataItem.id === vm.selectedDataItem.id) {
                e.sender.select(item);
                var row = e.sender.tbody.find("[data-uid='" + dataItem.uid + "']");
                row.addClass('k-state-selected');
                adjustScrollHeight(item);
                return true;
            }
        });
    }

    function adjustScrollHeight(selectedRow) {
        var div = $('#modal-content');
        var top = selectedRow ? selectedRow.offsetTop : div.position().top;
        var scrollFixedTop = $('thead').height() || 0;
        if (options.launchSrc === 'maintenance') {
            options.launchSrc = null;
        }
        div.scrollTop(top - scrollFixedTop);
    }

    function getSelectedRow(index) {
        return $('tbody tr.k-master-row:eq(' + index + ')')[0];
    }

    $scope.$watch(angular.bind(vm, function () {
        return vm.disableUpButton;
    }), function (newVal) {
        vm.disableUpButton = newVal;
    });

    $scope.$watch(angular.bind(vm, function () {
        return vm.disableDownButton;
    }), function (newVal) {
        vm.disableDownButton = newVal;
    });

    function moveRowUp() {
        var grid = vm.gridOptions.$widget.element.data('kendoGrid');
        var dataItem = grid.dataItem(grid.select());
        if (dataItem) {
            var index = grid.dataSource.indexOf(dataItem);
            if (index > 0) {
                var newIndex = index - 1;
                grid.dataSource.remove(dataItem);
                grid.dataSource.insert(newIndex, dataItem);
                vm.hasChanges = true;
            }
        }
    }

    function doSearch() {
        return nameTypesService.search();
    }

    function moveRowDown() {
        var grid = vm.gridOptions.$widget.element.data('kendoGrid');
        var dataItem = grid.dataItem(grid.select());
        if (dataItem) {
            var index = grid.dataSource.indexOf(dataItem);
            var maxIndex = grid.dataSource._data.length - 1;
            if (index < maxIndex) {
                var newIndex = index + 1;
                grid.dataSource.remove(dataItem);
                grid.dataSource.insert(newIndex, dataItem);
                vm.hasChanges = true;
            }
        }
    }

    function dismiss() {
        $uibModalInstance.close();
    }

    function updateUpDownButtonState(index, maxIndex) {
        if (index > 0 && index < maxIndex) {
            vm.disableUpButton = false;
            vm.disableDownButton = false;
        } else if (index === 0 && index < maxIndex) {
            vm.disableUpButton = true;
            vm.disableDownButton = false;
        } else if (index === maxIndex && maxIndex !== 0) {
            vm.disableUpButton = false;
            vm.disableDownButton = true;
        } else if (index === maxIndex) {
            vm.disableUpButton = true;
            vm.disableDownButton = true;
        }
    }

    function save() {
        var data = [];
        _.each(vm.gridOptions.data(), function (item, index) {
            data.push({
                id: item.id,
                priorityOrder: index
            });

        });
        nameTypesService.updateNameTypesSequence(data).then(function (response) {
            if (response.data.result.result === 'success') {
                nameTypesService.savedNameTypeIds.push(response.data.result.updatedId);
                notificationService.success();
                vm.selectedDataItem = null;
                vm.hasChanges = false;
                updateUpDownButtonState(0, 0);
            }
        }, function (response) {
            notificationService.alert({
                message: 'modal.alert.unsavedchanges',
                errors: _.where(response.data.errors, {
                    field: null
                })
            });
        });
    }
}