import { ChangeDetectionStrategy, Component, Renderer2 } from '@angular/core';
import * as _ from 'underscore';

@Component({
    template: '',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DragDropBaseComponent {
    dragControl: string;
    dropIndex: number;
    expandkeys: Array<string> = [];

    constructor(public renderer: Renderer2) { }

    setDragableAttributeForKendoGrid(selectedColumns): void {
        const tableRows = Array.from(document.querySelectorAll('#KendoGrid tbody tr'));
        tableRows.forEach((item, index) => {
            this.renderer.setStyle(item, 'cursor', 'all-scroll');
            this.renderer.setAttribute(item, 'draggable', 'true');
            this.renderer.setAttribute(item, 'data-item', JSON.stringify(selectedColumns[index]));
        });
    }

    onDragStart(e, dragControl, selectedColumns): void {
        this.dragControl = dragControl;
        const dataItem = e.srcElement.getAttribute('data-item');
        const item = _.find(selectedColumns, (sc: any) => {
            return sc.id === JSON.parse(dataItem).id;
        });
        e.dataTransfer.setData('text', item ? JSON.stringify(item) : dataItem);
    }

    onDragover(e, pointerPlace, selectedColumns): void {
        e.preventDefault();
        const targetElements = ['TD', 'SPAN', 'INPUT'];
        if (this.dragControl === 'kendoTreeView' && pointerPlace === 'kendoGrid') {
            _.contains(targetElements, e.target.tagName) ? this.dropIndex = this.closest(e.target, this.tableRow).rowIndex - 1 : this.dropIndex = selectedColumns.length;
        } else if (this.dragControl === 'kendoGrid' && pointerPlace === 'kendoGrid') {
          _.contains(targetElements, e.target.tagName) ? this.dropIndex = this.closest(e.target, this.tableRow).rowIndex - 1 : this.dropIndex =  selectedColumns.length;
        } else {
            this.dropIndex = 0;
        }
    }

    sortKendoTreeviewDataSet(dataset: any): any {
        const groupSort = dataset.filter(ds => ds.isGroup).sort((a, b) => (a.displayName > b.displayName) ? 1 : -1);
        const columnInSort = dataset.filter(ds => !ds.isGroup).sort((a, b) => (a.displayName > b.displayName) ? 1 : -1);

        return groupSort.concat(columnInSort);
    }

    handleCollapse(node): void {
        this.expandkeys = this.expandkeys.filter(k => k !== node.index);
    }

    handleExpand(node): void {
        this.expandkeys = this.expandkeys.concat(node.index);
    }

    isExpanded = (dataItem: any, index: string) => {
        return this.expandkeys.indexOf(index) > -1;
    };

    isTreeCollapsed(key: Array<string>, isClean: boolean): void {
        this.expandkeys = !isClean ? key : [];
    }

    reduce = (availableColumnsData: Array<any>) => {
        return availableColumnsData.reduce((acc, item) => {
            acc.push(item);

            return acc;
        }, []);
    };

    tableRow = (node) => {
        if (node.tagName) {
            return node.tagName.toLowerCase() === 'tr';
        }
    };

    closest = (node, predicate) => {
        while (node && !predicate(node)) {
            // tslint:disable-next-line: no-parameter-reassignment
            node = node.parentNode;
        }

        return node;
    };

    contains(text: string, term: string): boolean {
        return text.toLowerCase().indexOf(term.toLowerCase()) >= 0;
    }
}