import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  OnInit,
  Renderer2,
  ViewChild
} from '@angular/core';
import { BehaviorSubject, of } from 'rxjs';
import { map } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, scrollableMode } from 'shared/component/grid/ipx-kendo-grid.component';
import * as _ from 'underscore';
import { IpxBulkActionOptions } from './../../shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { KendoGridDataService } from './kendo-grid.data.service';

@Component({
  selector: 'kendo-grid-virtual-scrolling',
  templateUrl: './kendo-grid-virtual-scrolling.component.html',
  providers: [KendoGridDataService],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class KendoGridVirtualScrollingComponent implements OnInit, AfterViewInit {
  // gridView: GridDataResult;
  // data: Array<any>;
  pageSize = 10;
  skip = 0;
  // @ViewChild(GridComponent, { static: true }) wrapper: GridComponent;
  @ViewChild('resultsGrid', { static: true }) resultsGrid: IpxKendoGridComponent;
  gridOptions: IpxGridOptions;
  wrapperData: Array<any>;
  taskData: BehaviorSubject<any>;
  actions: Array<IpxBulkActionOptions>;

  constructor(private readonly renderer: Renderer2, private readonly roleSearchService: KendoGridDataService) {
    this.taskData = new BehaviorSubject<any>([]);
  }

  ngOnInit(): void {
    this.actions = this.initializeMenuActions();
    this.gridOptions = this.buildGridOptions();
  }

  private initializeMenuActions(): Array<IpxBulkActionOptions> {
    const menuItems: Array<IpxBulkActionOptions> = [{
      ...new IpxBulkActionOptions(),
      id: 'grant-permission-all',
      icon: 'cpa-icon cpa-icon-share',
      text: 'Grant permission for all',
      enabled: false,
      click: this.performOperations
    }, {
      ...new IpxBulkActionOptions(),
      id: 'deny-permission-all',
      icon: 'cpa-icon cpa-icon-check-circle',
      text: 'Deny permission for all',
      enabled: false,
      click: this.performOperations
    }, {
      ...new IpxBulkActionOptions(),
      id: 'clear-permission-all',
      icon: 'cpa-icon cpa-icon-ban',
      text: 'Clear permission for all',
      enabled: false,
      click: this.performOperations
    }];

    return menuItems;
  }

  buildGridOptions(): IpxGridOptions {
    return {
      autobind: true,
      persistSelection: true,
      scrollableOptions: { mode: scrollableMode.virtual, rowHeight: 15, height: 400 },
      navigable: false,
      selectable: {
        mode: 'multiple'
      },
      read$: (queryParams) => {
        if (_.any(this.taskData.getValue())) {
          const paginatedData = {
            data: this.taskData.getValue().slice(this.resultsGrid.wrapper.skip, this.resultsGrid.wrapper.skip + this.pageSize),
            pagination: {
              total: this.taskData.getValue().length
            }
          };

          return of(paginatedData);
        }

        return this.roleSearchService.runFullSearch(null, queryParams).pipe(map((response: Array<any>) => {
          this.taskData.next(response);
          const paginatedData = {
            data: response.slice(this.resultsGrid.wrapper.skip, this.resultsGrid.wrapper.skip + this.pageSize),
            pagination: {
              total: response.length
            }
          };

          return paginatedData;
        }));
      },
      columns: [
        {
          field: 'taskKey',
          title: 'taskKey',
          sortable: true
        },
        {
          field: 'taskName',
          title: 'Task Name',
          width: 250,
          sortable: true
        },
        {
          field: 'externalUse',
          title: 'External',
          template: true
        },
        {
          field: 'internalUse',
          title: 'Internal',
          template: true
        },
        {
          field: 'executePermission',
          title: 'Execute Permission',
          template: true
        },
        {
          field: 'insertPermission',
          title: 'Insert Permission',
          template: true
        },
        {
          field: 'updatePermission',
          title: 'Update Permission',
          template: true
        },
        {
          field: 'deletePermission',
          title: 'Delete Permission',
          template: true
        }
      ],
      bulkActions: this.actions,
      selectedRecords: {
        rows: {
          rowKeyField: 'taskKey',
          selectedKeys: []
        }
      }
    };
  }

  performOperations = (resultGrid: IpxKendoGridComponent) => {
    const selectedRowKeys = _.pluck(resultGrid.getRowSelectionParams().allSelectedItems, 'taskKey');
    const deselectedRowKeys = _.pluck(resultGrid.getRowSelectionParams().allDeSelectedItems, 'taskKey');
    const isAllPageSelect = resultGrid.getRowSelectionParams().isAllPageSelect;
  };

  ngAfterViewInit(): void {
    setTimeout(() => {
      this.applyScrollableHeight();
      this.resultsGrid.wrapper.pageSize = 20;
    }, 200);
  }

  applyScrollableHeight = (): void => {
    const element = this.resultsGrid.wrapper.wrapper.nativeElement;

    const scrollableElement = element.getElementsByClassName(
      'k-grid-content k-virtual-content'
    )[0];

    this.renderer.setStyle(scrollableElement, 'height', 400 + 'px');
  };

  onPageChanged(): void {
    console.log('pageChanged');
    console.log('pageSize : ' + this.resultsGrid.wrapper.pageSize);
    console.log('skip : ' + this.resultsGrid.wrapper.skip);
    this.resultsGrid.wrapper.data = {
      data: this.wrapperData.slice(this.resultsGrid.wrapper.skip, this.resultsGrid.wrapper.skip + this.resultsGrid.wrapper.pageSize),
      total: this.wrapperData.length
    };
  }
}
