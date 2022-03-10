import { ChangeDetectionStrategy, Component, OnInit, ViewChild } from '@angular/core';
import { map } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxKendoGridComponent, scrollableMode } from 'shared/component/grid/ipx-kendo-grid.component';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { ObjectTable, PermissionItemState, RoleSearchService } from './../role-search.service';

@Component({
  selector: 'ipx-roles-subject',
  templateUrl: './roles-subject.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RolesSubjectComponent implements TopicContract, OnInit {
  topic: Topic;
  viewData: any;
  gridOptions: IpxGridOptions;
  permissonChangedList: Array<any> = [];
  persistSubjectList: Array<any> = [];
  @ViewChild('resultsGrid', { static: true }) resultsGrid: IpxKendoGridComponent;
  isGridDirty = false;

  constructor(private readonly roleSearchService: RoleSearchService) {
  }

  ngOnInit(): void {
    if (this.topic.params && this.topic.params.viewData) {
      this.viewData = { ...this.topic.params.viewData };
    }
    this.gridOptions = this.buildGridOptions();
    Object.assign(this.topic, {
      getFormData: this.getFormData,
      isValid: this.isValid,
      isDirty: this.isDirty,
      clear: this.clear,
      revert: this.revert
    });
  }

  // tslint:disable-next-line: cyclomatic-complexity
  getFormData = (): any => {
    if (this.isGridDirty) {
      this.makeActionList();

      return { formData: { subjectDetails: this.permissonChangedList } };
    }
  };

  revert = (): any => {
    this.isGridDirty = false;
    this.permissonChangedList = [];
  };

  isDirty = (): boolean => {
    return this.isGridDirty;
  };

  isValid = (): boolean => {
    return true;
  };

  clear = (): void => {
    this.gridOptions._search();
  };

  onValueChanged(dataItem: any): void {
    this.isGridDirty = true;
    dataItem.isEdited = true;
    const exists = _.any(this.permissonChangedList, (item) => {
      return _.isEqual(item.topicKey, dataItem.topicKey);
    });
    if (!exists) {
      this.permissonChangedList.push(dataItem);
    } else {
      const index = _.findIndex(this.permissonChangedList, { topicKey: dataItem.topicKey });
      this.permissonChangedList[index] = dataItem;
    }
  }

  makeActionList = (): any => {
    const findExactRecord = _.filter(this.persistSubjectList, (p) =>
      _.some(this.permissonChangedList, (a) => (a.topicKey === p.topicKey))
    );
    // tslint:disable-next-line: cyclomatic-complexity
    this.permissonChangedList.filter(o1 => findExactRecord.some(o2 => {
      if (o1.topicKey === o2.topicKey) {
        if (o1.selectPermission !== null) {
          o1.oldSelectPermission = o2.selectPermission;
          if (o2.selectPermission === 0 && (o1.selectPermission === 1 || o1.selectPermission === 2)) {
            o1.selectPermissionStatus = PermissionItemState.added;
            o1.state = PermissionItemState.added;
          } else if ((o2.selectPermission === 1 || o2.selectPermission === 2) && o1.selectPermission === 0) {
            o1.selectPermissionStatus = PermissionItemState.deleted;
            o1.state = PermissionItemState.deleted;
          } else if ((o2.selectPermission === 1 || o2.selectPermission === 2) && (o1.selectPermission === 1 || o1.selectPermission === 2)) {
            o1.selectPermissionStatus = PermissionItemState.modified;
            o1.state = PermissionItemState.modified;
          }
        }
        o1.objectTable = ObjectTable.DataTopic;
        o1.levelTable = 'ROLE';
        o1.levelKey = o2.roleKey;
        o1.objectIntegerKey = o2.topicKey;
      }
    }));
  };

  buildGridOptions(): IpxGridOptions {
    return {
      autobind: true,
      navigable: false,
      customRowClass: (context) => {
        if (context.dataItem.isEdited) {
          return ' k-grid-edit-row';
        }

        return '';
      },
      scrollableOptions: { mode: scrollableMode.scrollable, height: 400 },
      read$: (queryParams) => {
        return this.roleSearchService.subjectDetails(this.topic.params.viewData.roleId).pipe(map((response: Array<any>) => {
          // tslint:disable-next-line: no-unbound-method
          this.persistSubjectList = _.map(response, _.clone);

          return response;
        }));
      },
      columns: [
        {
          field: 'topicName',
          title: 'Subject Name',
          width: 150
        },
        {
          field: 'description',
          title: 'Subject Description',
          width: 250
        },
        {
          field: 'selectPermission',
          title: 'Access',
          template: true,
          width: 50
        }
      ]
    };
  }
}
