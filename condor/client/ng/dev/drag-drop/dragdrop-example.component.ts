import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, Renderer2 } from '@angular/core';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import * as _ from 'underscore';
import { kendoGridData, kendoTreeViewData } from './data';

const tableRow = node => {
  if (node.tagName) {
    return node.tagName.toLowerCase() === 'tr';
  }
};

const closest = (node, predicate) => {
  while (node && !predicate(node)) {
    // tslint:disable-next-line: no-parameter-reassignment
    node = node.parentNode;
  }

  return node;
};

@Component({
  selector: 'dragdrop',
  templateUrl: './dragdrop-example.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class DragDropExampleComponent implements AfterViewInit, OnInit {
  kendoTreeViewData: Array<any> = kendoTreeViewData;
  kendoGridData: Array<any> = kendoGridData;
  gridOptions: IpxGridOptions;
  kendoTreeViewStore: Array<any> = [...kendoTreeViewData];
  kendoTreeViewStoreForFilter: Array<any> = [...kendoTreeViewData];
  dropIndex;
  dragStartControl: string;
  searchTerm: string;
  expandkeys: Array<string> = [];
  constructor(private readonly renderer: Renderer2, private readonly cdRef: ChangeDetectorRef) { }

  ngOnInit(): void {
    this.kendoTreeViewData = this.sortKendoTreeviewDataSet(this.kendoTreeViewData);
    this.gridOptions = this.buildGridOptions();
  }

  ngAfterViewInit(): void {
    this.setDragableAttributeForKendoGrid();
  }
  onkeyup(value: string, items: any): void {
    // tslint:disable-next-line: prefer-conditional-expression
    if (value === '') {
      this.kendoTreeViewData = this.sortKendoTreeviewDataSet(items);
      this.expandkeys = [];
    } else {
      const searchedItem = this.search(items, value);
      this.kendoTreeViewData = searchedItem;
      searchedItem.filter(x => x.parentId !== null).forEach((item, index) => {
        const checkForParent = this.kendoTreeViewStore.filter(x => x.id === item.parentId && x.parentId === null)[0];
        if (!this.kendoTreeViewData.find(x => x.id === checkForParent.id)) {
          this.kendoTreeViewData.splice(0, 0, checkForParent);
        }
      });
      this.kendoTreeViewData = this.sortKendoTreeviewDataSet(this.kendoTreeViewData);
      for (let i = 0; i < this.kendoTreeViewData.filter(x => x.isGroup === true).length; i++) {
        this.expandkeys.push(i.toString());
      }
    }
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
  search(items: Array<any>, term: string): Array<any> {
    return items.reduce((acc, item) => {
      if (this.contains(item.displayName, term)) {
        acc.push(item);
      }

      return acc;
    }, []);
  }

  contains(text: string, term: string): boolean {
    return text.toLowerCase().indexOf(term.toLowerCase()) >= 0;
  }
  buildGridOptions(): IpxGridOptions {
    return {
      selectable: {
        mode: 'single'
      },
      autobind: true,
      read$: (queryParams) => {
        return of(this.kendoGridData).pipe(delay(100));
      },
      columns: [{
        title: 'ID',
        field: 'id',
        width: 60,
        menu: true
      }, {
        title: 'Display Name',
        field: 'displayName',
        width: 160
      }, {
        title: 'Column Desc',
        field: 'columnDesc',
        width: 160
      }]
    };
  }

  setDragableAttributeForKendoGrid(): void {
    const tableRows = Array.from(document.querySelectorAll('#KendoGrid tbody tr'));
    tableRows.forEach((item, index) => {
      this.renderer.setAttribute(item, 'draggable', 'true');
      this.renderer.setAttribute(item, 'data-item', JSON.stringify(this.kendoGridData[index]));
    });
  }

  onDragStart(e, dragStartControl): void {
    this.dragStartControl = dragStartControl;
    const dataItem = e.srcElement.getAttribute('data-item');
    e.dataTransfer.setData('text', dataItem);
  }

  onDrop(e, dropZone): void {
    const data = e.dataTransfer.getData('text');
    const droppedItem = JSON.parse(data);
    if (dropZone === 'kendoGrid') {
      this.dragStartControl === 'kendoGrid' ? this.dropZoneKendoGridToKendoGrid(droppedItem) : this.dropZoneKendoGridFromTreeView(droppedItem);
    } else if (dropZone === 'kendoTreeView') {
      this.dropZoneKendoTreeViewFromKendoGrid(droppedItem);
    }
    this.cdRef.detectChanges();
    this.setDragableAttributeForKendoGrid();
  }

  // drag drop kendo grid rows within kendo grid
  dropZoneKendoGridToKendoGrid(droppedItem: any): void {
    const index = this.kendoGridData.findIndex(i => i.id === droppedItem.id);
    if (index !== -1) {
      this.kendoGridData.splice(index, 1);
      this.kendoGridData.splice(this.dropIndex, 0, droppedItem);
    }
  }

  // drag drop from kendo grid to kendo tree view
  dropZoneKendoTreeViewFromKendoGrid(droppedItem: any): void {
    const index = this.kendoGridData.findIndex(i => i.id === droppedItem.id);
    if (index !== -1) {
      this.kendoGridData.splice(index, 1);
      if (droppedItem.parentId === null) {
        this.kendoTreeViewData.splice(this.dropIndex, 0, droppedItem);
      } else {
        const checkForParent = this.kendoTreeViewStore.filter(x => x.id === droppedItem.parentId && x.parentId === null)[0];
        if (!this.kendoTreeViewData.find(x => x.id === checkForParent.id)) {
          this.kendoTreeViewData.splice(this.dropIndex, 0, checkForParent);
          this.kendoTreeViewData.splice(this.dropIndex, 0, droppedItem);
        } else {
          this.kendoTreeViewData.splice(this.dropIndex, 0, droppedItem);
        }
      }
      this.kendoTreeViewData = this.sortKendoTreeviewDataSet(this.kendoTreeViewData);
      this.kendoTreeViewStoreForFilter = this.kendoTreeViewData;
      this.gridOptions._search();
      if (this.searchTerm !== '' && this.searchTerm !== undefined) {
        this.onkeyup(this.searchTerm, this.kendoTreeViewStoreForFilter);
      }
    }
  }

  // drag drop from kendo tree view to kendo grid
  dropZoneKendoGridFromTreeView(droppedItem: any): void {
    const index = this.kendoTreeViewData.findIndex(i => i.id === droppedItem.id);
    if (index !== -1) {
      this.kendoTreeViewData.splice(index, 1);
      const checkForChild = this.kendoTreeViewData.filter(x => x.parentId === droppedItem.id);
      if (checkForChild === null || checkForChild.length === 0) {
        if (droppedItem.parentId !== null) {
          const isOnlyParentAvailable = this.kendoTreeViewData.filter(x => x.parentId === droppedItem.parentId);
          if (isOnlyParentAvailable.length === 0) {
            this.kendoTreeViewData = this.kendoTreeViewData.filter(obj => obj !== this.kendoTreeViewData.filter(x => x.id === droppedItem.parentId)[0]);
          }
        }
        this.kendoGridData.splice(this.dropIndex, 0, droppedItem);
      } else {
        checkForChild.forEach((item) => {
          this.kendoTreeViewData = this.kendoTreeViewData.filter(obj => obj !== item);
          this.kendoGridData.splice(this.dropIndex, 0, item);
        });
      }
    }
    this.kendoTreeViewData = this.updateKendo(this.kendoTreeViewData);
    this.kendoTreeViewStoreForFilter = this.kendoTreeViewData;
    if (this.searchTerm !== '' && this.searchTerm !== undefined) {
      this.onkeyup(this.searchTerm, this.kendoTreeViewStoreForFilter);
    }
  }

  updateKendo(items: Array<any>): Array<any> {
    return items.reduce((acc, item) => {
      acc.push(item);

      return acc;
    }, []);

  }

  onDragover(e, pointerPlace): void {
    e.preventDefault();
    e.target.tagName === 'TD' ? this.dropIndex = closest(e.target, tableRow).rowIndex : this.dropIndex = 0;
    console.log(e.target.tagName + ', ' + pointerPlace);
  }
  sortKendoTreeviewDataSet(dataset: any): any {
    const groupFirst = dataset.filter(x => x.isGroup === true).sort((a, b) => (a.displayName > b.displayName) ? 1 : -1);
    const columnInSort = dataset.filter(x => x.isGroup === false).sort((a, b) => (a.displayName > b.displayName) ? 1 : -1);
    const mixedData = groupFirst.concat(columnInSort);

    return mixedData;
  }
}