import { ChangeDetectionStrategy, Component, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { BehaviorSubject } from 'rxjs';
import { map } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, scrollableMode } from 'shared/component/grid/ipx-kendo-grid.component';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { ObjectTable, Permission, PermissionItemState, RoleSearchService } from './../role-search.service';

@Component({
  selector: 'ipx-roles-webpart',
  templateUrl: './roles-webpart.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RolesWebPartComponent implements TopicContract, OnInit {
  topic: Topic;
  viewData: any;
  formData?: any;
  form?: NgForm;
  gridOptions: IpxGridOptions;
  hasFilterChanged: BehaviorSubject<boolean>;
  permissonChangedList: Array<any> = [];
  persistWebpartList: Array<any> = [];
  @ViewChild('resultsGrid', { static: true }) resultsGrid: IpxKendoGridComponent;
  isGridDirty = false;

  constructor(private readonly roleSearchService: RoleSearchService) {
    this.hasFilterChanged = new BehaviorSubject<boolean>(false);
  }

  ngOnInit(): void {
    if (this.topic.params && this.topic.params.viewData) {
      this.viewData = { ...this.topic.params.viewData };
    }
    this.gridOptions = this.buildGridOptions();
    Object.assign(this.topic, {
      getFormData: this.getFormData,
      isDirty: this.isDirty,
      isValid: this.isValid,
      clear: this.clear,
      revert: this.revert
    });
  }

  isDirty = (): boolean => {
    return this.isGridDirty;
  };

  isValid = (): boolean => {
    return true;
  };

  getFormData = (): any => {
    if (this.isGridDirty) {
      this.makeActionList();

      return { formData: { webPartDetails: this.permissonChangedList } };
    }
  };

  revert = (): any => {
    this.isGridDirty = false;
    this.permissonChangedList = [];
  };

  clear = (): void => {
    this.gridOptions._search();
  };

  onValueChanged(dataItem: any, controlId: string): void {
    this.webPartPermission(dataItem, controlId);
    this.isGridDirty = true;
    dataItem.isEdited = true;
    const exists = _.any(this.permissonChangedList, (item) => {
      return _.isEqual(item.moduleKey, dataItem.moduleKey);
    });
    if (!exists) {
      this.permissonChangedList.push(dataItem);
    } else {
      const index = _.findIndex(this.permissonChangedList, { moduleKey: dataItem.moduleKey });
      this.permissonChangedList[index] = dataItem;
    }
  }

  webPartPermission(dataItem: any, controlId: string): void {
    switch (controlId) {
      case 's': {
        if (dataItem.selectPermission === Permission.Clear || dataItem.selectPermission === Permission.Deny) {
          dataItem.mandatoryPermission = dataItem.selectPermission;
        }
        break;
      }
      case 'm': {
        if (dataItem.mandatoryPermission === Permission.Grant) {
          dataItem.selectPermission = dataItem.mandatoryPermission;
        }
        break;
      }
      default: {
        if (dataItem.mandatoryPermission === Permission.Grant) {
          dataItem.selectPermission = dataItem.mandatoryPermission;
        }
        break;
      }
    }
  }

  makeActionList = (): any => {
    const findExactRecord = _.filter(this.persistWebpartList, (p) =>
      _.some(this.permissonChangedList, (a) => (a.moduleKey === p.moduleKey))
    );
    // tslint:disable-next-line: cyclomatic-complexity
    this.permissonChangedList.filter(o1 => findExactRecord.some(o2 => {
      if (o1.moduleKey === o2.moduleKey) {
        if (o2.selectPermission !== null && o2.mandatoryPermission !== null) {
          if (o1.selectPermission !== null && o1.mandatoryPermission !== null) {
            o1.oldSelectPermission = o2.selectPermission;
            o1.oldMandatoryPermission = o2.mandatoryPermission;
            if (o1.selectPermission === 0 && o1.mandatoryPermission === 0) {
              o1.state = PermissionItemState.deleted;
              o1.mandatoryPermission = null;
            } else {
              o1.state = PermissionItemState.modified;
            }
          }
        }
        if (o2.selectPermission === null && o2.mandatoryPermission === null) {
          o1.state = PermissionItemState.added;
          if (o1.selectPermission === 0 && o1.mandatoryPermission === 0) {
            o1.state = null;
          }
        }
        o1.objectTable = ObjectTable.Module;
        o1.levelTable = 'ROLE';
        o1.levelKey = o1.roleKey;
        o1.objectIntegerKey = o1.moduleKey;
      }
    }));
  };

  onFilterchanged = () => {
    this.hasFilterChanged.next(true);
  };

  buildGridOptions(): IpxGridOptions {
    return {
      autobind: true,
      navigable: false,
      filterable: true,
      customRowClass: (context) => {
        if (context.dataItem.isEdited) {
          return ' k-grid-edit-row';
        }

        return '';
      },
      scrollableOptions: { mode: scrollableMode.scrollable, height: 400 },
      read$: (queryParams) => {
        this.hasFilterChanged.next(false);

        return this.roleSearchService.webPartDetails(this.topic.params.viewData.roleId, queryParams).pipe(map((response: Array<any>) => {
          // tslint:disable-next-line: no-unbound-method
          this.persistWebpartList = _.map(response, _.clone);

          return response;
        }));

      },
      filterMetaData$: (column: GridColumnDefinition) => {
        return this.roleSearchService.runModuleFilterData$(column.field, this.topic.params.viewData.roleId);
      },
      columns: [
        {
          field: 'moduleTitle',
          title: 'Web Part Name',
          width: 150
        },
        {
          field: 'description',
          title: 'Web Part Description',
          width: 200
        },
        {
          field: 'selectPermission',
          title: 'Access',
          template: true,
          width: 50
        },
        {
          field: 'mandatoryPermission',
          title: 'Mandatory',
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
        }
      ]
    };
  }
}
