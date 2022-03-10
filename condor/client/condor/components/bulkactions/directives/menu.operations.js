angular.module('inprotech.components.bulkactions')
    .factory('BulkMenuOperations', function(menuSelection) {
        'use strict';

        function BulkMenuOperations(context) {
            this.context = context;
            this.selectedItems = [];
            this.isMultipagePageMode = false;
            this.updateSelection = updateSelection;
            this.setSelectedItems = setSelectedItems;
            this.findInSelectedItems = findInSelectedItems;
        }

        BulkMenuOperations.prototype = {
            selectAll: selectAll,
            clearAll: clearAll,
            clearSelectedItemsArray: clearSelectedItemsArray,
            selectionChange: selectionChange,
            anySelected: anySelected,
            selectedRecords: selectedRecords,
            selectedRecord: selectedRecord,
            selectPage: selectPage,
            initialiseMenuForPaging: initialiseMenuForPaging,
            singleSelectionChange: singleSelectionChange
        }

        return BulkMenuOperations;

        function anySelected(dataSource) {
            return (this.isMultipagePageMode) ?
                (this.selectedItems && this.selectedItems.length > 0) :
                _.any(dataSource, {
                    selected: true
                });
        }

        function selectAll(dataSource, isSelectAll) {
            var self = this;
            var totalSelectionCount = 0;
            if (dataSource) {
                _.each(dataSource, function(d) {
                    d.selected = isSelectAll;
                    resetInUse(d);
                });
                totalSelectionCount = (isSelectAll) ? dataSource.length : 0;
            }

            menuSelection.updateData(self.context, null, dataSource.length, totalSelectionCount, isSelectAll);
        }

        function selectPage(dataSource, isSelectPage) {
            var self = this;
            if (dataSource) {
                _.each(dataSource, function(d) {
                    d.selected = isSelectPage;
                    self.updateSelection(d);
                });
            }
            self.selectionChange(dataSource);
        }

        function clearAll(dataSource) {
            var self = this;
            var totalItems = 0;
            if (dataSource) {
                _.each(dataSource, function(d) {
                    d.selected = false;
                    resetInUse(d);
                });
                totalItems = dataSource.length;
            }
            self.clearSelectedItemsArray();
            menuSelection.updateData(self.context, null, totalItems, 0, false);
        }

        function clearSelectedItemsArray() {
            this.selectedItems.length = 0;
        }

        function selectionChange(dataSource, selectionsIds) {
            var self = this;

            if (selectionsIds) {
                if (selectionsIds.length > 0) {
                    for (var i = self.selectedItems.length - 1; i >= 0; i--) {
                        if (self.selectedItems[i]) {
                            if (selectionsIds.indexOf(self.selectedItems[i].id) < 0 && selectionsIds.indexOf(self.selectedItems[i].compositeId) < 0) {
                                self.selectedItems.splice(i, 1);
                            } else {
                                self.selectedItems[i].inUse = true;
                            }
                        }
                    }
                } else if (selectionsIds.length === 0) {
                    self.clearSelectedItemsArray();
                }
            }

            var totalSelectedOnPage = self.setSelectedItems(dataSource);
            var totalSelected = (self.isMultipagePageMode) ? self.selectedItems.length : totalSelectedOnPage;
            menuSelection.updateData(self.context, null, dataSource.length, totalSelected, (totalSelectedOnPage === dataSource.length));
        }

        function singleSelectionChange(dataSource, dataItem) {
            var self = this;
            this.updateSelection(dataItem);

            var pageSelected = true;
            if (self.selectedItems.length >= dataSource.length && dataItem.selected === true) {
                for (var i = 0; i < dataSource.length; i++) {
                    var item = this.findInSelectedItems(dataSource[i]);
                    if (item == null) {
                        pageSelected = false;
                        break;
                    }
                }
            } else {
                pageSelected = false
            }

            menuSelection.updateData(self.context, null, dataSource.length, self.selectedItems.length, pageSelected);
        }

        function selectedRecords(dataSource) {
            return (this.isMultipagePageMode) ? this.selectedItems :
                _.filter(dataSource, function(d) {
                    return d.selected === true;
                });
        }

        function selectedRecord(dataSource) {
            var self = this;
            return _.first(self.selectedRecords(dataSource));
        }

        // Mark in-use item in partial delete scenario for styling
        function resetInUse(data) {
            if (data.inUse) {
                data.inUse = false;
            }
        }

        function initialiseMenuForPaging(pageSize) {
            var self = this;
            if (pageSize) {
                self.isMultipagePageMode = true;
                menuSelection.updatePaginationInfo(self.context, true, pageSize);
            }
        }

        function updateSelection(dataItem) {
            if (this.isMultipagePageMode && dataItem) {

                var storedItem = this.findInSelectedItems(dataItem);
                if (dataItem.selected && storedItem == null) {
                    this.selectedItems.push(dataItem);
                } else if (!dataItem.selected && storedItem != null) {
                    this.selectedItems.splice(_.indexOf(this.selectedItems, storedItem), 1);
                    resetInUse(dataItem);
                }
            }
        }

        function findInSelectedItems(dataItem) {
            var storedItem = null;
            for (var i = 0; i < this.selectedItems.length; i++) {

                if ((dataItem.hasOwnProperty("compositeId") && angular.equals(this.selectedItems[i]["compositeId"], dataItem.compositeId)) ||
                    (dataItem.hasOwnProperty("id") && angular.equals(this.selectedItems[i]["id"], dataItem.id)) ||
                    (dataItem.hasOwnProperty("key") && angular.equals(this.selectedItems[i]["key"], dataItem.key))) {
                    storedItem = this.selectedItems[i];
                    break;
                }
            }
            return storedItem;
        }

        function setSelectedItems(data) {
            var pageSelected = 0;
            if (this.isMultipagePageMode === true) {
                if (this.selectedItems && this.selectedItems.length > 0 && (this.selectedItems[0].id || this.selectedItems[0].key)) {
                    _.each(this.selectedItems, function(s) {
                        var item = _.find(data, function(d) {
                            return (d.compositeId != null && angular.equals(d.compositeId, s.compositeId)) || ((d.id && d.id === s.id) || (d.key && d.key === s.key));
                        });
                        if (item) {
                            item.selected = true;
                            item.inUse = s.inUse;
                            pageSelected++;
                        }
                    });
                }
            } else {
                pageSelected = _.where(data, {
                    selected: true
                }).length;
            }
            return pageSelected;
        }
    });