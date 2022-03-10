'use strict';
namespace inprotech.components.grid {

    class KendoColumnPicker {
        public vm: KendoColumnPicker;
        public isExpand = false;
        public position: string;
        public gridOptions: any;
        public removableColumns = [];
        private helper: any;
        private $widget: any;
        private isCacheStored: boolean;
        private initialColumns = [];
        public hasColumnWithoutMenu: boolean;

        constructor(private $scope: any) {
            this.vm = this;
            if ($scope.$parent.vm) {
                this.position = $scope.$parent.vm.position;
                this.gridOptions = $scope.$parent.vm.gridOptions;
            }
            if (!this.position) {
                this.position = 'bottom';
            }

            Object.defineProperties(this, {
                'isCacheStored': { get: function () { return this.gridOptions.columnSelection.localSetting; } },
                'helper': { get: function () { return this.gridOptions.columnSelection.helper; } },
                '$widget': { get: function () { return this.gridOptions.$widget; } }
            });
            if (!this.isCacheStored) {
                this.initialColumns = _.map(this.$widget.columns, (col: any) => {
                    return { field: col.field, hidden: col.hidden || false }
                });
            }
        }

        public showColumns = () => {
            if (this.isExpand) {
                return;
            }

            let columns = this.$widget.getOptions().columns;
            this.hasColumnWithoutMenu = _.find(columns, (c: any) => {
                return !c.menu
            });

            columns.forEach((c) => {
                c.isShown = !c.hidden && c.menu
            });
            this.removableColumns = _.filter(columns, (c: any) => {
                return c.menu;
            });
        };

        public toggleColumn = (item) => {
            if (item.isShown && this.isLastSelectedColumn()) {
                return;
            }
            item.isShown = !item.isShown;
            if (item.isShown) {
                this.$widget.showColumn(item.field);
                this.addColumnToStore(item);
            } else {
                this.$widget.hideColumn(item.field);
                this.removeColumnFromStore(item);
            }

            this.$widget.autoFillGrid();
        };

        public reset = () => {
            this.resetColumnOrderAndDisplay();
            if (this.isCacheStored) {
                this.helper.reset();
            }
            this.isExpand = false;
        }

        public isLastSelectedColumn = (): boolean => {
            return this.selectedColumnsLength() === 1 && !this.hasColumnWithoutMenu;
        }

        public selectedColumnsLength = (): number => {
            return _.filter(this.removableColumns, (i) => {
                return i.isShown
            }).length;
        }

        private resetColumnOrderAndDisplay() {
            let defaultColumns = this.helper.defaultColumns || this.initialColumns;
            setTimeout(
                function (widget) {
                    _.each(defaultColumns, (column: any, defaultIndex: any) => {
                        let currentIndex = _.findIndex(widget.getOptions().columns, (c: any) => {
                            return c.field === column.field
                        });
                        if (currentIndex !== defaultIndex) {
                            widget.reorderColumn(defaultIndex, widget.columns[currentIndex]);
                        }
                    });

                    _.each(defaultColumns, (col: any) => {
                        if (col.hidden) {
                            widget.hideColumn(col.field);

                        } else {
                            widget.showColumn(col.field);
                        }
                    });

                    widget.autoFillGrid();

                }, 0, this.$widget);
        }

        private removeColumnFromStore(column) {
            if (this.isCacheStored) {
                this.helper.hideColumn(column)
            }
        }

        private addColumnToStore(column) {
            if (this.isCacheStored) {
                this.helper.showColumn(column);
            }
        }
    }

    angular.module('inprotech.components.grid')
        .component('ipKendoColumnPicker', {
            bindings: {
                gridOptions: '<',
                position: '<'
            },
            controllerAs: 'vm',
            controller: KendoColumnPicker,
            templateUrl: 'condor/components/grid/directives/kendoColumnPicker.html'
        });
}