import { AfterViewInit, ChangeDetectionStrategy, Component, OnInit, Renderer2, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { LocalSettings } from 'core/local-settings';
import { BehaviorSubject, fromEvent, of } from 'rxjs';
import { map } from 'rxjs/operators';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, scrollableMode } from 'shared/component/grid/ipx-kendo-grid.component';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { Action, ObjectTable, Permission, PermissionItemState, RoleSearchService } from './../role-search.service';

@Component({
  selector: 'ipx-roles-tasks',
  templateUrl: './roles-tasks.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RolesTasksComponent implements TopicContract, OnInit, AfterViewInit {
  topic: Topic;
  viewData: any;
  formData?: any;
  form?: NgForm;
  gridOptions: IpxGridOptions;
  taskData: BehaviorSubject<any>;
  hasFilterChanged: BehaviorSubject<boolean>;
  searchClicked: BehaviorSubject<boolean>;
  permissionSetToggled: BehaviorSubject<boolean>;
  pageSize = 10;
  @ViewChild('resultsGrid', { static: true }) resultsGrid: IpxKendoGridComponent;
  checkedCbx = 1;
  deniedCbx = 2;
  uncheckedCbx = 0;
  showDescriptionColumn: boolean;
  showOnlyPermissionSet: boolean;
  searchValue: string;
  isGridDirty = false;
  permissonChangedList: Array<any> = [];
  persistTaskList: Array<any> = [];
  actions: Array<IpxBulkActionOptions>;
  _resultsGrid: IpxKendoGridComponent;
  @ViewChild('resultsGrid') set taskGrid(grid: IpxKendoGridComponent) {
    if (grid && !(this._resultsGrid === grid)) {
      if (this._resultsGrid) {
        this._resultsGrid.rowSelectionChanged.unsubscribe();
      }
      this._resultsGrid = grid;
      this.subscribeRowSelectionChange();
    }
  }

  constructor(private readonly renderer: Renderer2, private readonly roleSearchService: RoleSearchService,
    readonly localSettings: LocalSettings) {
    this.taskData = new BehaviorSubject<any>([]);
    this.hasFilterChanged = new BehaviorSubject<boolean>(false);
    this.searchClicked = new BehaviorSubject<boolean>(false);
    this.permissionSetToggled = new BehaviorSubject<boolean>(false);
  }

  clear = (): void => {
    this.onClear();
  };

  ngOnInit(): void {
    if (this.topic.params && this.topic.params.viewData) {
      this.viewData = { ...this.topic.params.viewData };
    }
    this.showDescriptionColumn = this.localSettings.keys.userConfiguration.roles.showDescription.getLocal;
    this.showOnlyPermissionSet = false;
    this.actions = this.initializeMenuActions();
    this.gridOptions = this.buildGridOptions();

    Object.assign(this.topic, {
      getFormData: this.getFormData,
      isDirty: this.isDirty,
      isValid: this.isValid,
      clear: this.clear,
      revert: this.revert
    });
  }

  getFormData = (): any => {
    if (this.isGridDirty) {
      this.makeActionList();

      return { formData: { taskDetails: this.permissonChangedList } };
    }
  };

  revert = (): any => {
    this.isGridDirty = false;
    this.permissonChangedList = [];
  };

  isValid = (): boolean => {
    return true;
  };

  makeActionList = (): any => {
    const findExactRecord = _.filter(this.persistTaskList, (p) =>
      _.some(this.permissonChangedList, (a) => (a.taskKey === p.taskKey))
    );
    // tslint:disable-next-line: cyclomatic-complexity
    this.permissonChangedList.filter(o1 => findExactRecord.some(o2 => {
      if (o1.taskKey === o2.taskKey) {
        if (o1.isExecuteApplicable === 1) {
          o1.oldExecutePermission = o2.executePermission;
          if (!o2.executePermission && (o1.executePermission === 1 || o1.executePermission === 2 || !o1.executePermission)) {
            o1.executePermissionStatus = o2.executePermission === null ? PermissionItemState.added : null;
          } else if ((o2.executePermission === 1 || o2.executePermission === 2) && o1.executePermission === 0) {
            o1.executePermissionStatus = PermissionItemState.deleted;
          } else if ((o2.executePermission === 1 || o2.executePermission === 2) && (o1.executePermission === 1 || o1.executePermission === 2)) {
            o1.executePermissionStatus = PermissionItemState.modified;
          }
        }
        if (o1.isInsertApplicable === 1) {
          o1.oldInsertPermission = o2.insertPermission;
          if (!o2.insertPermission && (o1.insertPermission === 1 || o1.insertPermission === 2 || !o1.insertPermission)) {
            o1.insertPermissionStatus = o2.insertPermission === null ? PermissionItemState.added : null;
          } else if ((o2.insertPermission === 1 || o2.insertPermission === 2) && o1.insertPermission === 0) {
            o1.insertPermissionStatus = PermissionItemState.deleted;
          } else if ((o2.insertPermission === 1 || o2.insertPermission === 2) && (o1.insertPermission === 1 || o1.insertPermission === 2)) {
            o1.insertPermissionStatus = PermissionItemState.modified;
          }
        }
        if (o1.isUpdateApplicable === 1) {
          o1.oldUpdatePermission = o2.updatePermission;
          if (!o2.updatePermission && (o1.updatePermission === 1 || o1.updatePermission === 2 || !o1.updatePermission)) {
            o1.updatePermissionStatus = o2.updatePermission === null ? PermissionItemState.added : null;
          } else if ((o2.updatePermission === 1 || o2.updatePermission === 2) && o1.updatePermission === 0) {
            o1.updatePermissionStatus = PermissionItemState.deleted;
          } else if ((o2.updatePermission === 1 || o2.updatePermission === 2) && (o1.updatePermission === 1 || o1.updatePermission === 2)) {
            o1.updatePermissionStatus = PermissionItemState.modified;
          }
        }
        if (o1.isDeleteApplicable === 1) {
          o1.oldDeletePermission = o2.deletePermission;
          if (!o2.deletePermission && (o1.deletePermission === 1 || o1.deletePermission === 2 || !o1.deletePermission)) {
            o1.deletePermissionStatus = o2.deletePermission === null ? PermissionItemState.added : null;
          } else if ((o2.deletePermission === 1 || o2.deletePermission === 2) && o1.deletePermission === 0) {
            o1.deletePermissionStatus = PermissionItemState.deleted;
          } else if ((o2.deletePermission === 1 || o2.deletePermission === 2) && (o1.deletePermission === 1 || o1.deletePermission === 2)) {
            o1.deletePermissionStatus = PermissionItemState.modified;
          }
        }
      }
    }));
    // tslint:disable-next-line: cyclomatic-complexity
    _.each(this.permissonChangedList, (item) => {
      // Only Execute applicable
      if (item.isExecuteApplicable === 1 && item.isInsertApplicable !== 1 && item.isUpdateApplicable !== 1 && item.isDeleteApplicable !== 1) {
        item.state = item.executePermissionStatus;
      }
      // I/U/D applicable
      if (item.isExecuteApplicable !== 1 && item.isInsertApplicable === 1 && item.isUpdateApplicable === 1 && item.isDeleteApplicable === 1) {
        if ((item.insertPermissionStatus === PermissionItemState.added) && (item.updatePermissionStatus === PermissionItemState.added) &&
          (item.deletePermissionStatus === PermissionItemState.added)) {
          item.state = PermissionItemState.added;
        }
        if ((item.insertPermissionStatus === PermissionItemState.deleted) && (item.updatePermissionStatus === PermissionItemState.deleted) &&
          (item.deletePermissionStatus === PermissionItemState.deleted)) {
          item.state = PermissionItemState.deleted;
        }
        if ((item.insertPermissionStatus === PermissionItemState.modified) || (item.updatePermissionStatus === PermissionItemState.modified) ||
          (item.deletePermissionStatus === PermissionItemState.modified)) {
          item.state = PermissionItemState.modified;
        }
      }
      // E/I/U/D applicable
      if (item.isExecuteApplicable === 1 && item.isInsertApplicable === 1 && item.isUpdateApplicable === 1 && item.isDeleteApplicable === 1) {
        if ((item.executePermissionStatus === PermissionItemState.added) && (item.insertPermissionStatus === PermissionItemState.added) && (item.updatePermissionStatus === PermissionItemState.added) &&
          (item.deletePermissionStatus === PermissionItemState.added)) {
          item.state = PermissionItemState.added;
        }
        if ((item.executePermissionStatus === PermissionItemState.deleted) && (item.insertPermissionStatus === PermissionItemState.deleted) && (item.updatePermissionStatus === PermissionItemState.deleted) &&
          (item.deletePermissionStatus === PermissionItemState.deleted)) {
          item.state = PermissionItemState.deleted;
        }
        if ((item.executePermissionStatus === PermissionItemState.modified) || (item.insertPermissionStatus === PermissionItemState.modified) || (item.updatePermissionStatus === PermissionItemState.modified) ||
          (item.deletePermissionStatus === PermissionItemState.modified)) {
          item.state = PermissionItemState.modified;
        }
      }
      // Update applicable
      if (item.isExecuteApplicable !== 1 && item.isInsertApplicable !== 1 && item.isUpdateApplicable === 1 && item.isDeleteApplicable !== 1) {
        item.state = item.updatePermissionStatus;
      }
      // U/D applicable
      if (item.isExecuteApplicable !== 1 && item.isInsertApplicable !== 1 && item.isUpdateApplicable === 1 && item.isDeleteApplicable === 1) {
        if ((item.updatePermissionStatus === PermissionItemState.added) && (item.deletePermissionStatus === PermissionItemState.added)) {
          item.state = PermissionItemState.added;
        }
        if ((item.updatePermissionStatus === PermissionItemState.deleted) && (item.deletePermissionStatus === PermissionItemState.deleted)) {
          item.state = PermissionItemState.deleted;
        }
        if ((item.updatePermissionStatus === PermissionItemState.modified) || (item.deletePermissionStatus === PermissionItemState.modified)) {
          item.state = PermissionItemState.modified;
        }
      }
      item.objectTable = ObjectTable.Task;
      item.levelTable = 'ROLE';
      item.levelKey = item.roleKey;
      item.objectIntegerKey = item.taskKey;
    });
  };

  isDirty = (): boolean => {
    return this.isGridDirty;
  };

  ngAfterViewInit(): void {
    setTimeout(() => {
      this.resultsGrid.wrapper.pageSize = 20;
    }, 200);
    this.subscribeOnScroll();
  }

  subscribeOnScroll = () => {
    const content = document.querySelector('.main-content-scrollable');
    if (!!content) {
      const scroll$ = fromEvent(content, 'scroll').pipe(map(() => content));
      if (!!scroll$) {
        scroll$.subscribe(() => {
          const selectedTopic = this.roleSearchService.selectedTopic;
          if (selectedTopic === 'Tasks') {
            const hiddenElement: any = document.querySelector('#hiddenInput');
            hiddenElement.click();
          }
        });
      }
    }
  };

  togglePermissionSets(): void {
    this.scrollTop();
    this.permissionSetToggled.next(true);
    this.gridOptions._search();
  }

  onValueChanged(dataItem: any): void {
    this.isGridDirty = true;
    dataItem.isEdited = true;
    const exists = _.any(this.permissonChangedList, (item) => {
      return _.isEqual(item.taskKey, dataItem.taskKey);
    });
    if (!exists) {
      this.permissonChangedList.push(dataItem);
    } else {
      const index = _.findIndex(this.permissonChangedList, { taskKey: dataItem.taskKey });
      this.permissonChangedList[index] = dataItem;
    }
  }

  toggleDescriptionColumn(event: Event): void {
    this.localSettings.keys.userConfiguration.roles.showDescription.setLocal(event);
    this.gridOptions.columns.forEach(col => {
      if (col.field === 'description') {
        col.hidden = !event;
      }
    });
    this.scrollTop();
    this.gridOptions._search();
  }

  scrollTop = () => {
    const element = this.resultsGrid.wrapper.wrapper.nativeElement;

    const scrollableElement = element.getElementsByClassName(
      'k-grid-content k-virtual-content'
    )[0];

    scrollableElement.scrollLeft = 0;
    scrollableElement.scrollTop = 0;
  };

  onSearch = (value?: any) => {
    this.searchValue = value?.value;
    this.searchClicked.next(true);
    this.gridOptions._search();
  };

  onFilterchanged = () => {
    this.hasFilterChanged.next(true);
  };

  onClear = () => {
    this.searchValue = '';
    this._resultsGrid.clearSelection();
    this.searchClicked.next(true);
    this.gridOptions._search();
  };

  subscribeRowSelectionChange = () => {
    this._resultsGrid.rowSelectionChanged.subscribe((event) => {
      const anySelected = event.rowSelection.length > 0;
      const grantAll = this.actions.find(x => x.id === 'grantAll');
      const denyAll = this.actions.find(x => x.id === 'denyAll');
      const clearAll = this.actions.find(x => x.id === 'clearAll');
      const grantPermission = this.actions.find(x => x.id === 'grant-permission');
      const denyPermission = this.actions.find(x => x.id === 'deny-permission');
      const clearPermission = this.actions.find(x => x.id === 'clear-permission');
      grantAll.enabled = anySelected;
      denyAll.enabled = anySelected;
      clearAll.enabled = anySelected;
      grantPermission.enabled = anySelected;
      denyPermission.enabled = anySelected;
      clearPermission.enabled = anySelected;
    });
  };

  anySelectedSubject = new BehaviorSubject<boolean>(false);

  buildGridOptions(): IpxGridOptions {
    this.resultsGrid.rowSelectionChanged.subscribe((event) => {
      const anySelected = event.rowSelection.length > 0;
      this.anySelectedSubject.next(anySelected);
    });

    return {
      autobind: true,
      persistSelection: true,
      scrollableOptions: { mode: scrollableMode.virtual, rowHeight: 15, height: 400 },
      navigable: false,
      filterable: true,
      selectable: {
        mode: this.viewData.canUpdateRole ? 'multiple' : 'single'
      },
      bulkActions: this.actions,
      selectedRecords: {
        rows: {
          rowKeyField: 'taskKey',
          selectedKeys: []
        }
      },
      customRowClass: (context) => {
        if (context.dataItem.isEdited) {
          return ' k-grid-edit-row';
        }

        return '';
      },
      read$: (queryParams) => {
        this.resultsGrid.wrapper.pageSize = this.pageSize;
        const criteria = {
          searchText: this.searchValue,
          showOnlyPermissionSet: this.showOnlyPermissionSet,
          searchDescription: this.showDescriptionColumn
        };
        if (_.any(this.taskData.getValue()) && !this.searchClicked.getValue() && !this.permissionSetToggled.getValue() && !this.hasFilterChanged.getValue()) {
          const tasks = this.taskData.getValue();
          const paginatedData = {
            data: tasks.slice(this.resultsGrid.wrapper.skip, this.resultsGrid.wrapper.skip + this.pageSize),
            pagination: {
              total: tasks.length
            }
          };

          return of(paginatedData);
        }

        return this.roleSearchService.taskDetails(this.topic.params.viewData.roleId, criteria, queryParams).pipe(map((response: Array<any>) => {
          if (this.searchClicked.getValue() && this.permissonChangedList.length > 0) {
            _.each(this.permissonChangedList, (item) => {
              const value = _.find(response, (r: any) => {
                return r.taskKey === item.taskKey;
              });
              if (value) {
                _.extend(value, item);
              }
            });
            this.taskData.next(response);
          } else {
            this.permissonChangedList = [];
            this.taskData.next(response);
            this.persistTaskList = [];
            // tslint:disable-next-line: no-unbound-method
            this.persistTaskList = _.map(this.taskData.getValue(), _.clone);
          }

          const paginatedData = {
            data: response.slice(this.resultsGrid.wrapper.skip, this.resultsGrid.wrapper.skip + this.pageSize),
            pagination: {
              total: response.length
            }
          };

          this.hasFilterChanged.next(false);
          this.permissionSetToggled.next(false);
          this.searchClicked.next(false);

          return paginatedData;
        }));
      },
      filterMetaData$: (column: GridColumnDefinition) => {
        return this.roleSearchService.runFilterMetaSearch$(column.field, this.topic.params.viewData.roleId);
      },
      columns: [
        {
          field: 'taskName',
          title: 'Task Name',
          width: 150,
          sortable: true
        },
        {
          field: 'description',
          title: 'Task Description',
          width: 170,
          hidden: !this.showDescriptionColumn
        },
        {
          field: 'executePermission',
          title: 'Execute',
          width: 70,
          template: true

        },
        {
          field: 'insertPermission',
          title: 'Insert',
          width: 70,
          template: true
        },
        {
          field: 'updatePermission',
          title: 'Update',
          template: true,
          width: 70
        },
        {
          field: 'deletePermission',
          title: 'Delete',
          template: true,
          width: 70
        },
        {
          field: 'feature',
          title: 'Feature',
          template: true,
          filter: true,
          width: 170
        },
        {
          field: 'subFeature',
          title: 'Sub-Feature',
          template: true,
          filter: true,
          width: 170
        },
        {
          field: 'release',
          title: 'Release',
          template: true,
          filter: true,
          width: 100
        }
      ]
    };
  }

  private initializeMenuActions(): Array<IpxBulkActionOptions> {
    const menuItems: Array<IpxBulkActionOptions> = [];

    menuItems.push(
      {
        ...new IpxBulkActionOptions(),
        id: 'grantAll',
        icon: 'cpa-icon cpa-icon-check-square-o',
        text: 'roleDetails.tasks.grantAll',
        enabled: false,
        click: () => this.applyPermissions(this.resultsGrid, Action.All, Permission.Grant)
      }
    );

    menuItems.push({
      ...new IpxBulkActionOptions(),
      id: 'denyAll',
      icon: 'cpa-icon cpa-icon-minus-square',
      text: 'roleDetails.tasks.denyAll',
      enabled: false,
      click: () => this.applyPermissions(this.resultsGrid, Action.All, Permission.Deny)
    });

    menuItems.push({
      ...new IpxBulkActionOptions(),
      id: 'clearAll',
      icon: 'cpa-icon cpa-icon-square-o',
      text: 'roleDetails.tasks.clearAll',
      enabled: false,
      click: () => this.applyPermissions(this.resultsGrid, Action.All, Permission.Clear)
    });

    menuItems.push({
      ...new IpxBulkActionOptions(),
      id: 'grant-permission',
      icon: 'cpa-icon cpa-icon-check-square-o',
      text: 'roleDetails.tasks.grantPermission',
      enabled: false,
      items: [
        {
          ...new IpxBulkActionOptions(),
          id: 'execute',
          text: 'roleDetails.tasks.execute',
          enabled: true,
          click: () => this.applyPermissions(this.resultsGrid, Action.Execute, Permission.Grant)
        }, {
          ...new IpxBulkActionOptions(),
          id: 'insert',
          text: 'roleDetails.tasks.insert',
          enabled: true,
          click: () => this.applyPermissions(this.resultsGrid, Action.Insert, Permission.Grant)
        }, {
          ...new IpxBulkActionOptions(),
          id: 'update',
          text: 'roleDetails.tasks.update',
          enabled: true,
          click: () => this.applyPermissions(this.resultsGrid, Action.Update, Permission.Grant)
        }, {
          ...new IpxBulkActionOptions(),
          id: 'delete',
          text: 'roleDetails.tasks.delete',
          enabled: true,
          click: () => this.applyPermissions(this.resultsGrid, Action.Delete, Permission.Grant)
        }
      ]
    });

    menuItems.push({
      ...new IpxBulkActionOptions(),
      id: 'deny-permission',
      icon: 'cpa-icon cpa-icon-minus-square',
      text: 'roleDetails.tasks.denyPermission',
      enabled: false,
      items: [
        {
          ...new IpxBulkActionOptions(),
          id: 'execute',
          text: 'roleDetails.tasks.execute',
          enabled: true,
          click: () => this.applyPermissions(this.resultsGrid, Action.Execute, Permission.Deny)
        }, {
          ...new IpxBulkActionOptions(),
          id: 'insert',
          text: 'roleDetails.tasks.insert',
          enabled: true,
          click: () => this.applyPermissions(this.resultsGrid, Action.Insert, Permission.Deny)
        }, {
          ...new IpxBulkActionOptions(),
          id: 'update',
          text: 'roleDetails.tasks.update',
          enabled: true,
          click: () => this.applyPermissions(this.resultsGrid, Action.Update, Permission.Deny)
        }, {
          ...new IpxBulkActionOptions(),
          id: 'delete',
          text: 'roleDetails.tasks.delete',
          enabled: true,
          click: () => this.applyPermissions(this.resultsGrid, Action.Delete, Permission.Deny)
        }
      ]
    });

    menuItems.push({
      ...new IpxBulkActionOptions(),
      id: 'clear-permission',
      icon: 'cpa-icon cpa-icon-square-o',
      text: 'roleDetails.tasks.clearPermission',
      enabled: false,
      items: [
        {
          ...new IpxBulkActionOptions(),
          id: 'execute',
          text: 'roleDetails.tasks.execute',
          enabled: true,
          click: () => this.applyPermissions(this.resultsGrid, Action.Execute, Permission.Clear)
        }, {
          ...new IpxBulkActionOptions(),
          id: 'insert',
          text: 'roleDetails.tasks.insert',
          enabled: true,
          click: () => this.applyPermissions(this.resultsGrid, Action.Insert, Permission.Clear)
        }, {
          ...new IpxBulkActionOptions(),
          id: 'update',
          text: 'roleDetails.tasks.update',
          enabled: true,
          click: () => this.applyPermissions(this.resultsGrid, Action.Update, Permission.Clear)
        }, {
          ...new IpxBulkActionOptions(),
          id: 'delete',
          text: 'roleDetails.tasks.delete',
          enabled: true,
          click: () => this.applyPermissions(this.resultsGrid, Action.Delete, Permission.Clear)
        }
      ]
    });

    return menuItems;
  }

  applyPermissions = (resultGrid: IpxKendoGridComponent, actionType: string, permission?: number): any => {
    const selections = resultGrid.getSelectedItems('taskKey');
    const params = resultGrid.getRowSelectionParams();
    const taskList = this.taskData.getValue();
    if (params.isAllPageSelect) {
      let selectedIds = taskList.map(x => x.taskKey);
      if (params.allDeSelectIds.length > 0) {
        params.allDeSelectIds = params.allDeSelectIds.map(Number);
        selectedIds = selectedIds.filter(item => params.allDeSelectIds.indexOf(item) < 0);
      }
      this.permission(selectedIds, taskList, actionType, permission);
    } else {
      this.permission(selections, taskList, actionType, permission);
    }
  };

  permission = (applyChange: any, taskList: any, actionType: any, permission: any): any => {
    for (const val of applyChange) {
      const selectedTasks = taskList.find(x => x.taskKey === val);
      if (actionType === Action.All) {
        if (selectedTasks.isExecuteApplicable === 1) {
          selectedTasks.executePermission = permission;
        }
        if (selectedTasks.isInsertApplicable === 1) {
          selectedTasks.insertPermission = permission;
        }
        if (selectedTasks.isDeleteApplicable === 1) {
          selectedTasks.deletePermission = permission;
        }
        if (selectedTasks.isUpdateApplicable === 1) {
          selectedTasks.updatePermission = permission;
        }
      }
      if (actionType === Action.Execute) {
        if (selectedTasks.isExecuteApplicable === 1) {
          selectedTasks.executePermission = permission;
        }
      }
      if (actionType === Action.Insert) {
        if (selectedTasks.isInsertApplicable === 1) {
          selectedTasks.insertPermission = permission;
        }
      }
      if (actionType === Action.Update) {
        if (selectedTasks.isUpdateApplicable === 1) {
          selectedTasks.updatePermission = permission;
        }
      }
      if (actionType === Action.Delete) {
        if (selectedTasks.isDeleteApplicable === 1) {
          selectedTasks.deletePermission = permission;
        }
      }
      this.onValueChanged(selectedTasks);
    }
  };
}