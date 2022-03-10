import { QueryList } from '@angular/core';
import * as _ from 'underscore';
import { IpxGridOptions } from './ipx-grid-options';
import { GridColumnDefinition, PageSettings } from './ipx-grid.models';
import { IpxKendoGridComponent } from './ipx-kendo-grid.component';
import { EditTemplateColumnFieldDirective, TemplateColumnFieldDirective } from './ipx-template-column-field.directive';

export class GridHelper {
    readonly storePageSizeToLocalStorage = (newSize: number, pageLocalSetting: any): { oldPagesize?: number } => {
        const pageSetting = pageLocalSetting;
        if (pageSetting) {
            const oldPageSize = pageSetting.getLocal;
            if (oldPageSize !== newSize) {
                pageSetting.setLocal(newSize);
            }

            return { oldPagesize: oldPageSize };
        }

        return {};
    };

    readonly setColumnsPreference = (dataOptions: any) => {
        if (dataOptions.columnSelection) {
            const fromLocal = dataOptions.columnSelection.localSetting.getLocal;
            if (fromLocal instanceof Array && fromLocal.length > 0) {
                let tempColumns = [];
                fromLocal.map((col: { field: string; hidden: boolean; index: number }) => {
                    const column = dataOptions.columns.filter((doColumn: GridColumnDefinition) => { return col.field === doColumn.field; });
                    if (column && column.length === 1) {
                        tempColumns = [...tempColumns, ...column];
                    }
                });
                const fixedIcons = dataOptions.columns.filter((fixed: GridColumnDefinition) => { return fixed.title === '' && fixed.fixed; });
                const filteredFixed = _.filter(fixedIcons, (item: any) => {
                    return !_.contains(_.pluck(tempColumns, 'field'), item.field);
                });

                dataOptions.columns = [...filteredFixed, ...tempColumns];

                return { dataOptions };
            }
        }
    };

    readonly hasClasses = (element: HTMLElement, classNames: string): boolean => {
        const namesList = this.toClassList(classNames);

        return Boolean(this.toClassList(element.className).find((className) => namesList.indexOf(className) >= 0));
    };

    readonly toClassList = (classNames: string) => String(classNames).trim().split(' ');

    readonly closest = (node, predicate) => {
        while (node && !predicate(node)) {
            // tslint:disable-next-line: no-parameter-reassignment
            node = node.parentNode;
        }

        return node;
    };

    readonly rebuildColumnTemplates = (dataOptions: IpxGridOptions,
        templates: QueryList<TemplateColumnFieldDirective>,
        editTemplates: QueryList<EditTemplateColumnFieldDirective>) => {
        dataOptions.columns.forEach(c => {
            if (c.template) {
                const template = c.template === true ? (templates.find(t => t.key === c.field) || c).template : c.template;
                if (typeof template !== 'boolean') {
                    c._templateResolved = template as any;
                }

                const editableFields = editTemplates.filter(t => t.key === c.field);
                if (editableFields.length > 0) {
                    const editTemplate = c.template === true ? editableFields[0].template : c.template;
                    if (editTemplate) {
                        c._editTemplateResolved = editTemplate;
                    }
                }
            }
        });

        return { dataOptions };
    };

    readonly isAnyColumnLokced = (dataOptions: IpxGridOptions): boolean => {
        return _.any(dataOptions.columns, (c) => c.locked) &&
            _.any(dataOptions.columns, (c) => !c.locked);
    };

    static manualPageChange(grid: IpxKendoGridComponent, data: Array<any>, skip: number, take: number): void {
        grid.allItems = data;
        grid.wrapper.data = {
            data: data.slice(skip, skip + take),
            total: data.length
        };
    }
}