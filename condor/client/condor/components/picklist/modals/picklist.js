angular.module('inprotech.components.picklist')
    .run(function(modalService, store) {
        'use strict';

        modalService.register('Picklist', 'PicklistModalController', 'condor/components/picklist/modals/picklist.html', {
            windowClass: 'centered picklist-window',
            backdropClass: 'centered',
            size: 'lg'
        });

        store.local.default('picklist.pageSize', 20);
    });

angular.module('inprotech.components.picklist')
    .controller('PicklistModalController',
        function($log, $scope, $uibModalInstance, $http, apiResolverService, persistables, persistenceService, states, notificationService,
            kendoGridBuilder, store, options, validCombinationConfirmationService, pagerHelperService, $state, splitterBuilder) {
            'use strict';

            var keyColumn, valueColumn, preventCopyColumns, search, duplicateFromServer, splitter,
                vm = this,
                canMaintain = options.canMaintain;

            vm.entity = options.entity;
            vm.isRestMod = true;
            vm.windowLabel = options.windowLabel;
            vm.fieldLabel = options.fieldLabel;
            vm.externalScope = options.externalScope;
            vm.searchValue = options.searchValue;
            vm.selectedItems = options.selectedItems == null ? [] : options.selectedItems.slice(0);
            vm.modalState = states.initialising;
            vm.size = options.size;
            vm.currentView = 'search';
            vm.hasColumnMenu = options.columnMenu;
            vm.showApply = options.multipick;
            vm.showPreview = options.previewable;
            vm.isPreviewActive = vm.isPreviewActive = options.previewable === true ? (store.local.get('showPicklistPreview') === true ? true : false) : false;
            vm.qualifiers = options.qualifiers;
            vm.rawResults = [];
            vm.hasInlineGrid = false;
            vm.initialViewData = options.initialViewData;
            vm.canAddAnother = options.canAddAnother;
            vm.isAddAnotherSaved = false;
            vm.dimmedColumnName = options.dimmedColumnName;

            if (options.initFunction) {
                options.initFunction(vm);
            }

            vm.searchInWindow = function(skipPreSearch, clearSelection) {
                if (vm.modalState === states.initialising) {
                    return;
                }

                if (options.preSearch && !skipPreSearch) {
                    options.preSearch(vm);
                }

                if (vm.externalScope && !_.isUndefined(vm.externalScope.picklistSearch)) {
                    vm.externalScope.picklistSearch = true;
                }

                if (clearSelection) {
                    if (options.multipick && vm.selectedItems) {
                        vm.selectedItems.splice(0, vm.selectedItems.length);
                    } else {
                        vm.selectedItem = null;
                    }
                }

                search().then(function() {
                    vm.externalScope.picklistSearch = false;
                });

            };

            vm.cancel = function() {
                $uibModalInstance.dismiss('Cancel');
            };

            vm.returnSelectedItems = function() {
                var returnData = _.map(vm.selectedItems, function(i) {
                    return JSON.parse(JSON.stringify(i));
                });
                $uibModalInstance.close(returnData);
            };

            vm.save = function() {
                if (vm.maintenance && vm.maintenance.$validate) {
                    vm.maintenance.$validate();
                }

                if (vm.maintenance.$valid) {
                    if (vm.onBeforeSave) {
                        vm.onBeforeSave(vm.entry, executeSave);
                        if (!vm.continueSave)
                            return;
                    } else {
                        vm.isAddAnotherSaved = vm.canAddAnother && vm.maintenanceState === 'adding';
                        persistenceService.save(vm.maintenance, vm.entry, vm.hasInlineGrid, afterSave);
                    }
                }
            };

            function executeSave() {
                if (!vm.continueSave)
                    return;
                else {
                    vm.isAddAnotherSaved = vm.canAddAnother && vm.maintenanceState === 'adding';
                    persistenceService.save(vm.maintenance, vm.entry, vm.hasInlineGrid, afterSave);
                }
            }

            vm.saveWithoutValidate = function() {
                vm.isAddAnotherSaved = vm.canAddAnother && vm.maintenanceState === 'adding';
                persistenceService.save(vm.maintenance, vm.entry, vm.hasInlineGrid, afterSave);
            };

            vm.abandon = function() {
                var force = !vm.maintenance.$dirty;
                var inlineGridDirty = vm.hasInlineGrid && vm.isInlineGridDirty();
                vm.isAddAnother = false;

                persistenceService.abandon(vm.entry, vm.maintenanceState, force, changeToSearchViewAndRefresh, inlineGridDirty, function() {
                    persistenceService.save(vm.maintenance, vm.entry, vm.hasInlineGrid, afterSave);
                });
            };

            vm.isSaveEnabled = function() {
                var formValid = vm.maintenance.$dirty && vm.maintenance.$valid;
                if (!vm.hasInlineGrid) return formValid;

                if (vm.hasInlineGrid) {
                    return (vm.maintenance.$dirty || vm.isInlineGridDirty()) &&
                        (vm.maintenance.$valid && !vm.hasInlineGridError())
                }
            };

            vm.isSaveVisible = function() {
                return vm.maintenanceState !== 'viewing';
            };

            vm.delete = function(selectedEntry) {
                var additionalIdentifier = vm.getValidCombinationIdentifier(selectedEntry);
                persistables.prepare(vm.entity, states.deleting, selectedEntry, keyColumn.field, false, additionalIdentifier, vm.isRestMod)
                    .entry
                    .$then(function(data) {
                        var message = 'picklistmodal.confirm.delete';
                        if (selectedEntry.confirmDeleteMessage) {
                            message = selectedEntry.confirmDeleteMessage;
                        }

                        persistenceService.delete(data, function(callbackParams) {
                            if (callbackParams && callbackParams.rerunSearch) {
                                changeToSearchViewAndRefresh(true);
                                return;
                            }
                            vm.gridOptions.removeItem(selectedEntry);
                            var rows = vm.rawResults.$metadata;
                            vm.rawResults.$metadata.ids = _.filter(rows.ids, function(item) {
                                return item != selectedEntry.key;
                            });

                        }, angular.noop, additionalIdentifier, message);
                    });
            };

            vm.getValidCombinationIdentifier = function(entry) {
                if (vm.isValidCombinationPicklist()) {
                    return {
                        validCombinationKeys: options.extendQuery(),
                        isDefaultJurisdiction: entry.isDefaultJurisdiction
                    };
                }
                return null;
            };

            vm.isValidCombinationPicklist = function() {
                return vm.externalScope && vm.externalScope[(vm.entity || 'combination')] && !!vm.externalScope[(vm.entity || 'combination')]();
            }

            vm.toggleSelectAll = function() {
                _.each(vm.gridOptions.dataSource.data(), function(d) {
                    d.selected = vm.isSelectAll;
                    vm.updateSelected(d);
                });
            };

            vm.changeToAddView = function(selectedItem) {
                vm.changeToMaintenanceView(states.adding, selectedItem);
            };

            vm.changeToEditView = function(selectedItem) {
                vm.changeToMaintenanceView(states.updating, selectedItem, options);
            };

            vm.changeToDetailView = function(selectedItem) {
                vm.changeToMaintenanceView(states.viewing, selectedItem, options);
            };

            vm.changeToDuplicateView = function(selectedItem) {
                vm.changeToMaintenanceView(states.duplicating, selectedItem);
            };

            vm.changeToMaintenanceView = function(action, selectedItem, options) {
                if (!selectedItem) {
                    selectedItem = {};
                }
                var additionalIdentifier = vm.getValidCombinationIdentifier(selectedItem);

                var exceptColumns = _.pluck(preventCopyColumns, 'field');


                if (options && options.editUriState) {
                    var url = $state.href(options.editUriState, {
                        id: selectedItem.key,
                        navigatedSource: 'jurisdictionpicklist'
                    });
                    window.open(url, '_blank');
                    return false;
                }

                if (action === states.duplicating && duplicateFromServer) {   
                    vm.navigation = null;                 
                    copyFromServer(exceptColumns, selectedItem, additionalIdentifier);
                } else {
                    vm.maintenanceState = action;
                    vm.currentView = 'maintenance';

                    var allKeys = vm.rawResults.$metadata ? vm.rawResults.$metadata.ids : null;

                    if (allKeys && (action === states.updating || action === states.viewing)) {
                        vm.navigation = createNavigation({
                            allKeys: allKeys,
                            isFormDirty: function() {
                                return vm.maintenance && vm.maintenance.$dirty;
                            },
                            onNavigation: function(key) {
                                var obj = {};
                                obj[keyColumn.field] = key;
                                var r = persistables.prepare(vm.entity,
                                    action,
                                    obj,
                                    keyColumn.field,
                                    exceptColumns,
                                    additionalIdentifier,
                                    vm.isRestMod
                                );

                                r.entry.$then(function(data) {
                                    vm.entry = data;
                                    if (vm.maintenanceTemplate == null) {
                                        vm.maintenanceTemplate = r.template;
                                    } else if (vm.maintenanceTemplate === r.template) {
                                        $scope.$broadcast('dynamicContent.reload');
                                    }
                                });
                            }
                        });

                        vm.navigation.navigateByKey(selectedItem[keyColumn.field]);
                    } else {
                        vm.navigation = null;
                        var r = persistables.prepare(vm.entity,
                            action,
                            selectedItem,
                            keyColumn.field,
                            exceptColumns,
                            additionalIdentifier,
                            vm.isRestMod);

                        vm.maintenanceTemplate = r.template;

                        r.entry.$then(function(data) {
                            vm.entry = data;
                            if (data.$response && data.$response.data.data.error) {
                                notificationService.alert({
                                    title: 'modal.unableToComplete',
                                    message: data.$response.data.data.error.message
                                }).then(null, function() {
                                    $uibModalInstance.close();
                                });
                            } else {
                                if (vm.qualifiers) {
                                    vm.entry = angular.extend(vm.entry, vm.qualifiers);
                                }
                                if (vm.maintenanceState === states.updating || vm.maintenanceState === states.viewing) {
                                    $scope.$broadcast('dynamicContent.reload');
                                }
                            }
                        });
                    }
                }
            };

            vm.getMaintenanceTitle = function() {
                switch (vm.maintenanceState) {
                    case 'adding':
                    case 'duplicating':
                        return 'picklistmodal.add';
                    case 'updating':
                        return 'picklistmodal.edit';
                    case 'viewing':
                        return 'picklistmodal.view';
                }
            };

            if (options.apiUriName || (!vm.entity)) {
                vm.isRestMod = false;
                vm.picklistService = persistables.resolve(options.apiUriName, vm.isRestMod);
                vm.picklistService.init(initDataModel, (!vm.entity), options.apiUrl); // backward compatible with both existings mode
            } else {
                vm.isRestMod = true;
                vm.picklistService = persistables.resolve(vm.entity, vm.isRestMod);
                vm.picklistService.init(initDataModel);
            }


            function copyFromServer(exceptColumns, selectedItem, additionalIdentifier) {
                var r = persistables.prepare(vm.entity,
                    states.updating,
                    selectedItem,
                    keyColumn.field,
                    exceptColumns,
                    additionalIdentifier,
                    vm.isRestMod);

                vm.maintenanceState = states.duplicating;
                vm.currentView = 'maintenance';
                vm.maintenanceTemplate = r.template;
                r.entry.$then(function(data) {
                    exceptColumns.push(keyColumn.field);
                    var duplicate = data.$duplicate(exceptColumns); //TODO duplicate function here or later? 
                    angular.extend(duplicate, additionalIdentifier);
                    r.api.$build(duplicate).$then(function(dupeData) {
                        vm.entry = dupeData;
                        $scope.$broadcast('dynamicContent.reload');
                    })
                });
            }

            function initDataModel(metadata) {
                var all = metadata.columns;
                var allowed = canMaintain || false;
                var ctx = metadata.maintainability;
                var columns;

                duplicateFromServer = metadata.duplicateFromServer;

                vm.maintainability = {
                    canAdd: allowed && ctx && ctx.canAdd,
                    canEdit: allowed && ctx && ctx.canEdit,
                    canDelete: allowed && ctx && ctx.canDelete
                };

                if (metadata.maintainabilityActions) {
                    vm.maintenanceActions = {
                        canAdd: metadata.maintainabilityActions.allowAdd,
                        canEdit: metadata.maintainabilityActions.allowEdit,
                        canDelete: metadata.maintainabilityActions.allowDelete,
                        canDuplicate: metadata.maintainabilityActions.allowDuplicate,
                        canView: metadata.maintainabilityActions.allowView
                    };
                }

                columns = _.filter(all || [], function(item) {
                    return !item.hidden;
                });

                keyColumn = _.find(all, function(item) {
                    return item.key === true;
                });

                valueColumn = _.find(all, function(item) {
                    return item.description === true;
                });

                if (!keyColumn || !valueColumn) {
                    $log.debug('keyColumn or valueColumn not found for picklist: ' + vm.entity);
                }

                preventCopyColumns = _.filter(all, function(item) {
                    return item.preventCopy === true;
                });

                if (canMaintain && (vm.maintenanceActions && vm.maintenanceActions.canView || vm.maintainability.canAdd || vm.maintainability.canEdit || vm.maintainability.canDelete)) {
                    columns.push({
                        title: 'picklistmodal.actions',
                        template: buildActions(vm.maintainability, vm.maintenanceActions),
                        menu: false
                    });
                }

                if (options.columns) {
                    if (vm.entity) {
                        var i = options.columns.filter(function(c) {
                            return columns.some(function(g) {
                                return c.field === g.field;
                            });
                        });

                        i.forEach(function(item) {
                            var v = _.find(columns, function(x) {
                                return x.field === item.field;
                            });
                            angular.extend(v, item);
                        });
                    } else {
                        columns = options.columns;
                    }
                }

                var readFn = function(queryParams) {
                    if (vm.externalScope && (!_.isUndefined(vm.externalScope.picklistSearch) || !vm.isRestMod))
                        vm.externalScope.picklistSearch = true;

                    var query = buildSearchQuery(vm.searchValue, queryParams, options.extendQuery);

                    return vm.picklistService.$search(query).$asPromise().then(function(data) {

                        vm.rawResults = data;
                        setSelectedItems(data);

                        if (vm.externalScope && !_.isUndefined(vm.externalScope.picklistSearch || !vm.isRestMod))
                            vm.externalScope.picklistSearch = false;

                        return {
                            data: data.$encode(),
                            pagination: data.$metadata.pagination
                        };
                    });
                };

                vm.gridOptions = buildGridOptions(readFn, columns, options.multipick);

                search = vm.gridOptions.search;

                vm.modalState = states.normal;
                if (vm.showPreview) {
                    configureSplitter();
                }
            }

            vm.showColumns = function() {
                var widget = vm.gridOptions.$widget;
                var o = widget.getOptions();
                var columns = o.columns;

                var shownColumns = store.local.get('picklist.' + vm.entity + '.columns');
                if (!shownColumns) {
                    shownColumns = _.pluck(_.filter(columns, function(column) {
                        return !column.hideByDefault;
                    }), 'field');
                    store.local.set('picklist.' + vm.entity + '.columns', shownColumns);
                }

                columns.forEach(function(c) {
                    c.isShown = _.contains(shownColumns, c.field)
                });
                vm.removableColumns = _.filter(columns, function(c) {
                    return c.menu;
                });
            };

            vm.toggleColumn = function(item) {
                var widget = vm.gridOptions.$widget;
                _.findWhere(vm.removableColumns, {
                    field: item.field
                }).isShown = !item.isShown;
                if (item.isShown) {
                    widget.showColumn(item.field);
                } else {
                    widget.hideColumn(item.field);
                }
            };

            function buildGridOptions(readFn, columns, isMultipick) {
                if (vm.entity) {
                    var existingColumnsSetting = store.local.get('picklist.' + vm.entity + '.columns');
                    if (existingColumnsSetting) {
                        _.each(columns, function(column) {
                            column.hidden = !_.contains(existingColumnsSetting, column.field) && column.menu;
                        });
                    } else {
                        _.each(columns, function(column) {
                            column.hidden = column.hideByDefault && column.menu;
                        });
                    }
                }

                if (isMultipick) {
                    columns.unshift({
                        headerTemplate: '<ip-checkbox ng-model=\"vm.isSelectAll\" ng-change=\"vm.toggleSelectAll()\" ip-tooltip=\"{{:: \'grid.toggleAllNone\' | translate }}\">',
                        template: '<ip-checkbox ng-model=\"dataItem.selected\" ng-change=\"vm.updateSelected(dataItem)\">',
                        width: '35px',
                        fixed: true,
                        locked: true
                    });
                }

                columns.forEach(function(c) {
                    if (c.dataType && c.dataType.toLowerCase() === 'boolean') {
                        c.template = function(data) {
                            return '<input ' + (data[c.field] === true ? 'checked' : '') + ' type="checkbox" disabled="true">';
                        };
                    }
                });

                var gridOptions = kendoGridBuilder.buildOptions($scope, {
                    id: 'picklistResults' + (vm.entity ? "-" + vm.entity : "") + (vm.isValidCombinationPicklist() ? "-valid" : ""),
                    onSelect: function() {
                        vm.gridOptions.selectFocusedRow();
                    },
                    onGridCreated: function() {
                        if (vm.navigation) {
                            var pageSize = parseInt(store.local.get('picklist.pageSize'));
                            var pageIndex = parseInt(vm.navigation.currentIndex / pageSize);

                            vm.gridOptions.dataSource.query({
                                page: pageIndex + 1,
                                pageSize: store.local.get('picklist.pageSize')
                            });
                        } else {
                            vm.gridOptions.dataSource.query({
                                page: 1,
                                pageSize: store.local.get('picklist.pageSize')
                            });
                        }
                        var widget = vm.gridOptions.$widget;
                        var columns = widget.getOptions().columns;
                        var existingColumnsSetting = store.local.get('picklist.' + vm.entity + '.columns');
                        if (existingColumnsSetting) {
                            _.each(columns, function(column) {
                                if (column.menu) {
                                    if (_.contains(existingColumnsSetting, column.field))
                                        widget.showColumn(column.field);
                                    else
                                        widget.hideColumn(column.field);
                                }
                            });
                        }
                    },
                    onDataBound: function() {
                        if (vm.navigation && vm.navigation.key) {
                            var keyToHighlight = vm.navigation.key;
                            setTimeout(function() {
                                vm.gridOptions.highlightSingleItem(keyToHighlight);
                            }, 10);
                        }

                        if (vm.showPreview) {
                            togglePreviewPane();
                        }
                    },
                    pageable: {
                        pageSize: store.local.get('picklist.pageSize'),
                        pageSizes: [5, 10, 15, 20]
                    },
                    onPageSizeChanged: function(pageSize) {
                        store.local.set('picklist.pageSize', pageSize);
                    },
                    readFilterMetadata: function(column) {
                        return getColumnFilterData(column);
                    },
                    autoBind: false,
                    navigatable: true,
                    read: readFn,
                    columns: columns,
                    selectable: 'row',
                    change: selectItem,
                    columnHide: function(e) {
                        var cols = store.local.get('picklist.' + vm.entity + '.columns');
                        store.local.set('picklist.' + vm.entity + '.columns', _.reject(cols, function(col) {
                            return col && (col === e.column.field);
                        }));
                    },
                    columnShow: function(e) {
                        var cols = store.local.get('picklist.' + vm.entity + '.columns');
                        store.local.set('picklist.' + vm.entity + '.columns', _.union(cols, [e.column.field]));
                    },
                    schema: vm.entity ? {
                        model: {
                            id: keyColumn ? keyColumn.field : 'key'
                        }
                    } : null /* if simple api ignore keyColumn*/
                });

                if (vm.dimmedColumnName) {
                    gridOptions.rowAttributes = function(data, el) {
                        if (data[vm.dimmedColumnName] === true) {
                            $(el).addClass('dim');
                        }
                    }
                }

                return gridOptions;
            }

            function getColumnFilterData(column) {
                return $http.get(column.filterApi + '/filterdata/' + column.field, {
                    params: {
                        search: vm.searchValue || ""
                    }
                }).then(function(response) {
                    return response.data;
                });
            }

            function buildActions(maintainability, maintenanceActions) {
                var html = '<div class="grid-actions">';

                if (canMaintain && maintenanceActions.canView && !maintainability.canEdit)
                    html += '<ip-icon-button class="btn-no-bg" button-icon="info-circle" ip-tooltip="{{::\'View\' | translate }}" data-ng-click="vm.changeToDetailView(dataItem); $event.stopPropagation();"></ip-icon-button>';

                if (maintainability.canEdit && maintenanceActions.canEdit) {
                    html += '<ip-icon-button class="btn-no-bg" button-icon="pencil-square-o" ip-tooltip="{{::\'Edit\' | translate }}" data-ng-click="vm.changeToEditView(dataItem); $event.stopPropagation();"></ip-icon-button>';
                }

                if (maintainability.canAdd && maintenanceActions.canDuplicate) {
                    html += '<ip-icon-button class="btn-no-bg" button-icon="files-o" ip-tooltip="{{::\'Duplicate\' | translate }}" data-ng-click="vm.changeToDuplicateView(dataItem); $event.stopPropagation();"></ip-icon-button>';
                }

                if (maintainability.canDelete && maintenanceActions.canDelete) {
                    html += '<ip-icon-button class="btn-no-bg" button-icon="trash" ip-tooltip="{{::\'Delete\' | translate }}" data-ng-click="vm.delete(dataItem);$event.stopPropagation();"></ip-icon-button>';
                }

                html += '</div>';

                return html;
            }

            function goToPageForKey(key) {
                var newPage = pagerHelperService.getPageForId(vm.rawResults.$metadata.ids, key, store.local.get('picklist.pageSize'));
                if (newPage && vm.gridOptions.dataSource.page() !== newPage.page) {
                    vm.gridOptions.dataSource.page(newPage.page);
                }
            }

            function changeToSearchViewAndRefresh(rerunSearch) {
                vm.currentView = 'search';
                if (vm.navigation) {
                    goToPageForKey(vm.entry.key);
                    var keyToHighlight = vm.entry.key;
                    setTimeout(function() {
                        /* timeout so that maintenance modal get closed */
                        vm.gridOptions.highlightSingleItem(keyToHighlight);
                    }, 10);

                }
                vm.entry = null;
                if (vm.maintenanceState === "adding" || vm.maintenanceState === "duplicating") {
                    vm.navigation = null;
                }
                vm.maintenanceState = null;
                if (rerunSearch === true || vm.isAddAnotherSaved) {
                    search({
                        preventPageReset: true
                    });
                }
            }

            function afterSave(response) {
                if (response.result === 'confirmation' && vm.externalScope) {
                    validCombinationConfirmationService.confirm(vm.entry, response, onConfirmAfterSave);
                    return;
                }

                if (vm.confirmAfterSave && response.result) {
                    vm.confirmAfterSave(vm.entry, response, executeAfterConfirmation);
                } else {
                    executeAfterConfirmation(vm, response);
                }
            }

            function executeAfterConfirmation(viewModel, response) {
                notificationService.success();
                if (vm.isValidCombinationPicklist()) {
                    if (vm.canAddAnother && vm.isAddAnother && vm.maintenanceState === "adding") {
                        addAnother();
                    } else {
                        changeToSearchViewAndRefresh(true);
                    }
                } else {
                    var key = response.key;
                    var listItem = vm.gridOptions.dataSource.get(key) || {};

                    // if new entry was saved, server will return its key                
                    if (!viewModel.entry.key) viewModel.entry.key = key;
                    if (!listItem.key) listItem.key = key;

                    if (viewModel.maintenanceState === "adding" || viewModel.maintenanceState === "duplicating") {
                        if (vm.rawResults.$metadata && vm.rawResults.$metadata.ids) {
                            var index = viewModel.navigation ? viewModel.navigation.currentIndex : 0;
                            vm.rawResults.$metadata.ids.splice(index, 0, key);
                        }
                    }

                    var detailObject = viewModel.entry;
                    if (viewModel.navigation) {
                        viewModel.maintenance.$setPristine();
                        if (viewModel.onAfterSave) {
                            viewModel.onAfterSave();
                        }
                    } else if (vm.canAddAnother && vm.isAddAnother && vm.maintenanceState === "adding") {
                        addAnother();

                    } else {
                        changeToSearchViewAndRefresh(response.rerunSearch);
                    }

                    if (!response.rerunSearch) {
                        // this will pick properties from just edited model and put them into grid item
                        if (viewModel.updateListItemFromMaintenance) {
                            viewModel.updateListItemFromMaintenance(listItem, detailObject);
                        } else {
                            listItem = detailObject;
                        }
                        vm.gridOptions.highlightAfterEditing(listItem);
                    }
                }

                function addAnother() {
                    vm.navigation = null;
                    viewModel.maintenance.$setPristine();
                    $scope.$broadcast('dynamicContent.reload');
                    vm.changeToMaintenanceView(states.adding, null);
                }
            }

            function onConfirmAfterSave(validEntity) {
                vm.entry = validEntity;
                vm.save();
            }

            vm.updateSelected = function(item) {
                var storedItem = findItemInSelection(item);

                if (item.selected && storedItem == null) {
                    vm.selectedItems.push(item);
                } else if (!item.selected && storedItem != null) {
                    vm.selectedItems.splice(_.indexOf(vm.selectedItems, storedItem), 1);
                }
            }

            function findItemInSelection(item) {
                var storedItem;
                if (item.id != null && item.id !== '') {
                    storedItem = _.findWhere(vm.selectedItems, {
                        id: item.id
                    });
                }

                if (storedItem == null && item.key != null && item.key !== '') {
                    storedItem = _.findWhere(vm.selectedItems, {
                        key: item.key
                    })
                }

                return storedItem || null;
            }

            function selectItem() {
                if (options.multipick) {
                    var item = this.dataItem(this.select());
                    if (!vm.isPreviewActive) {
                        item.selected = !item.selected;
                    }
                    vm.updateSelected(item);
                    $scope.$apply();
                } else {
                    var selectEntry = this.dataItem(this.select()).toJSON();
                    $uibModalInstance.close(selectEntry);
                }
            }

            function setSelectedItems(data) {
                if (vm.selectedItems && vm.selectedItems.length > 0 && (vm.selectedItems[0].id != null || vm.selectedItems[0].key != null)) {
                    _.each(vm.selectedItems, function(s) {
                        var item = _.find(data, function(d) {
                            return (d.id != null && d.id === s.id) || (d.key != null && d.key === s.key);
                        });
                        if (item) {
                            item.selected = true;
                        }
                    });
                }

                // tick the header checkbox if all are selected
                vm.isSelectAll = _.every(data, function(d) {
                    return d.selected === true;
                });
            }

            function buildSearchQuery(searchValue, queryParams, extendQuery) {
                var query = {
                    search: searchValue || '',
                    params: JSON.stringify(queryParams)
                };

                extendQuery = extendQuery || _.identity;

                return extendQuery(query);
            }

            function createNavigation(options) {
                return {
                    key: null,
                    currentIndex: null,
                    isFirstDisabled: null,
                    isPrevDisabled: null,
                    isNextDisabled: null,
                    isLastDisabled: null,
                    totalCount: options.allKeys.length,
                    next: function() {
                        if (!this.isNextDisabled) {
                            this.navigate(this.currentIndex + 1);
                        }
                    },
                    prev: function() {
                        if (!this.isPrevDisabled) {
                            this.navigate(this.currentIndex - 1);
                        }
                    },
                    first: function() {
                        if (!this.isFirstDisabled) {
                            this.navigate(0);
                        }
                    },
                    last: function() {
                        if (!this.isLastDisabled) {
                            this.navigate(options.allKeys.length - 1);
                        }
                    },
                    navigate: function(index) {
                        if (options.isFormDirty()) {
                            var _this = this;
                            notificationService.discard().then(function() {
                                _this._navigate(index);
                            });
                        } else {
                            this._navigate(index);
                        }
                    },
                    navigateByKey: function(id) {
                        var index = options.allKeys.indexOf(id);
                        this.navigate(index);
                    },
                    _navigate: function(index) {
                        this.currentIndex = index;
                        var key = options.allKeys[index];
                        this.key = key;
                        options.onNavigation(key);

                        this.isFirstDisabled = this.isPrevDisabled = this.currentIndex === 0;
                        this.isNextDisabled = this.isLastDisabled = this.currentIndex === options.allKeys.length - 1;

                        if (vm.maintenance) {
                            vm.maintenance.$setPristine();
                        }
                    }
                };
            }

            function configureSplitter() {
                var picklistSearchResultsPane = kendo.ui.SplitterPane = {
                    collapsible: false,
                    collapsed: false
                };
                var picklistResultsPreviewPane = kendo.ui.SplitterPane = {
                    collapsible: true,
                    collapsed: true,
                    size: '35%'
                };
                splitter = splitterBuilder.BuildOptions('picklistSearchResults', {
                    panes: [picklistSearchResultsPane, picklistResultsPreviewPane]
                });
                vm.splitterOptions = splitter.options;
            }

            function togglePreviewPane() {
                $scope.$watch('vm.isPreviewActive', function() {
                    store.local.set('showPicklistPreview', vm.isPreviewActive);
                    splitter.resizePanesHeight('picklistPreviewPane');
                    splitter.togglePane('picklistPreviewPane', !vm.isPreviewActive);
                });
            }
        });