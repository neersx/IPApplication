'use strict';
namespace inprotech.components.grid {

    class ColumnPicker {
        defaultColumns: any;
        constructor(public localSetting: inprotech.core.LocalSetting, public suffix = '') {
            this.defaultColumns = [];
        }

        public initColumnDisplay = (columns) => {
            this.defaultColumns = this.mapColumnField(columns);

            let savedColumns = this.localSetting.getLocalwithSuffix(this.suffix);
            if (!savedColumns || savedColumns.length === 0) {
                return columns;
            }

            let revisedColumns = [];
            savedColumns.forEach(column => {
                let col = _.find(columns, (c: any) => {
                    return c.field === column.field
                });
                if (col) {
                    revisedColumns.push(_.extend(col, { hidden: column.hidden }));
                }
            });

            let newColumns = _.filter(columns, (col: any) => {
                return !_.find(revisedColumns, c => {
                    return c.field === col.field
                })
            });

            newColumns.forEach(column => {
                let index = _.indexOf(columns, column);
                revisedColumns.splice(index, 0, column);
            });

            if (newColumns.length > 0) {
                this.localSetting.setLocal(this.mapColumnField(revisedColumns), this.suffix);
            }

            _.each(revisedColumns, (column: any) => {
                column.hidden = column.hidden && column.menu;
            });

            columns = revisedColumns;
            return columns;
        }

        public updateColumnOrder = (oldIndex, newIndex, col) => {
            let columns = this.savedOrDefaultColumns();
            let temp = columns[oldIndex];
            columns = _.without(columns, temp);
            columns.splice(newIndex, 0, temp);

            this.localSetting.setLocal(this.mapColumnField(columns), this.suffix);
        }

        public hideColumn = (column) => {
            this.setColumnDisplay(column, true);
        }

        public showColumn = (column) => {
            this.setColumnDisplay(column, false);
        }

        public reset = () => {
            this.localSetting.removeLocal(this.suffix);
        }

        private setColumnDisplay = (column, hidden) => {
            let cols = this.savedOrDefaultColumns();
            let col = _.find(cols, (c: any) => {
                return c.field === column.field
            });
            if (col) {
                col.hidden = hidden;
            }
            this.localSetting.setLocal(cols, this.suffix);
        }

        private mapColumnField = (columns) => {
            return _.map(columns, (col: any) => {
                return { field: col.field, hidden: col.hidden || false }
            });
        }

        private savedOrDefaultColumns = () => {
            return this.localSetting.getLocalwithSuffix(this.suffix) || angular.copy(this.defaultColumns);
        }
    }

    export class ColumnPickerHelper {
        static factory() {
            let instance = () =>
                new ColumnPickerHelper();
            return instance;
        }
        constructor() {

        }

        public init(localSetting: inprotech.core.LocalSetting, suffix = ''): ColumnPicker {
            let r: ColumnPicker = new ColumnPicker(localSetting, suffix);
            return r;
        }
    }
    angular.module('inprotech.components.grid').factory('columnPickerHelper', ColumnPickerHelper.factory());
}