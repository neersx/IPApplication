import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/angular';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LocalSettings } from 'core/local-settings';
import { BehaviorSubject } from 'rxjs';
import { takeWhile } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { Topic, TopicOptions } from 'shared/component/topics/ipx-topic.model';
import { GridNavigationService } from 'shared/shared-services/grid-navigation.service';
import * as _ from 'underscore';
import { RoleSearchService } from '../role-search.service';
import { RolesOverviewComponent } from './roles-overview.component';
import { RolesSubjectComponent } from './roles-subject.component';
import { RolesTasksComponent } from './roles-tasks.component';
import { RolesWebPartComponent } from './roles-webpart.component';

@Component({
  selector: 'ipx-role-details',
  templateUrl: './role-details.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RoleDetailsComponent implements OnInit {
  @Input() viewData: any;
  @Input() stateParams: {
    id: number,
    rowKey: string
  };
  roleNameTitle: string;
  topics: { [key: string]: Topic };
  options: TopicOptions;
  hasPreviousState = false;
  navData: {
    keys: Array<any>,
    totalRows: number,
    pageSize: number,
    fetchCallback(currentIndex: number): any
  };
  navigationState: string;
  isShowDelete = false;
  canUpdateRole = false;
  roleIndex: number;
  roleIds: Array<any>;
  showNavigation: BehaviorSubject<boolean> = new BehaviorSubject(true);
  showNavigation$ = this.showNavigation.asObservable();
  rowKey: any;
  isLoading = false;

  constructor(private readonly roleSearchService: RoleSearchService,
    private readonly navService: GridNavigationService,
    private readonly state: StateService,
    private readonly ipxNotificationService: IpxNotificationService,
    private readonly notificationService: NotificationService,
    private readonly translate: TranslateService,
    private readonly localSettings: LocalSettings) { }

  ngOnInit(): void {
    if (this.stateParams.id) {
      this.roleIds = this.localSettings.keys.navigation.ids.getLocal;
      this.hasPreviousState = (this.stateParams.id && this.stateParams.rowKey) ? true : false;
      this.isShowDelete = this.viewData.canDeleteRole && !this.protectedRoles();
      this.canUpdateRole = this.viewData.canUpdateRole;
      this.roleIndex = _.indexOf(this.roleIds, this.stateParams.id);
    }
    this.roleSearchService._roleName$.subscribe(r => {
      if (r !== null) {
        this.roleNameTitle = r;
      }
    });

    this.init();
    this.navigationState = this.state.current.name;
    this.navData = {
      ...this.navService.getNavigationData(),
      fetchCallback: (currentIndex: number): any => {
        return this.navService.fetchNext$(currentIndex).toPromise();
      }
    };
    if (!this.stateParams.rowKey) {
      this.rowKey = _.first(this.navData.keys.filter(x => x.value === this.stateParams.id.toString())).key;
    }
    this.showNavigation.next(true);
  }

  protectedRoles = (): Boolean => {
    return _.any(this.roleSearchService.protectedRoles(), (role: any) => {
      return _.isEqual(role.roleId, this.stateParams.id);
    });
  };

  deleteRole = (): void => {
    if (this.stateParams.id) {
      const notificationRef = this.ipxNotificationService.openDeleteConfirmModal('roleDetails.deletemsg');
      notificationRef.content.confirmed$.pipe(takeWhile(() => !!notificationRef))
        .subscribe(() => {
          const ids: Array<number> = [];
          ids.push(this.stateParams.id);
          this.roleSearchService.deleteroles(ids).subscribe((response: any) => {
            if (response.hasError) {
              const message = this.translate.instant('roleDetails.alert.alreadyInUseOnDetail');
              const title = 'modal.unableToComplete';
              this.notificationService.alert({
                title,
                message
              });
            } else {
              this.roleSearchService.runSearch(this.localSettings.keys.navigation.searchCriteria.getLocal, this.localSettings.keys.navigation.queryParams.getLocal).subscribe(res => {
                this.notificationService.success();
                this.navigateToNext();
              });
            }
          });
        });
    }
  };

  activeTopicChanged(topicKey: string): void {
    this.roleSearchService.setSelectedTopic(topicKey);
  }

  onSave = (): void => {
    if (this.isFormDirty()) {
      this.isLoading = true;
      const roleDetails = this.getFormData();
      this.roleSearchService.updateRoleDetails(roleDetails.formData).subscribe(result => {
        if (result) {
          this.notificationService.success();
          this.isLoading = false;
          this.clearAndRevert();
        }
      });
    }
  };

  revert = (): void => {
    if (this.isFormDirty()) {
      const roleDetailsNotificationModalRef = this.ipxNotificationService.openDiscardModal();
      roleDetailsNotificationModalRef.content.confirmed$.subscribe(() => {
        this.clearAndRevert();
      });
    }
  };

  clearAndRevert = (): void => {
    _.each(this.topics, (t: any) => {
      if (_.isFunction(t.clear) && (_.isFunction(t.revert))) {
        t.revert();
        t.clear();
      }
    });
  };

  private getFormData(): any {
    if (!this.topics) {
      return null;
    }
    const data = { filterCriteria: { searchRequest: {} as any }, formData: {} };
    _.each(this.topics, (t: any) => {
      if (_.isFunction(t.getFormData)) {
        const topicData = t.getFormData();
        if (topicData) {
          _.extend(data.formData, topicData.formData);
        }
      }
    });

    return data;
  }

  isFormDirty(): boolean {
    const isDirty = _.any(this.topics, (t: any) => {
      return _.isFunction(t.isDirty) && t.isDirty();
    });

    return isDirty;
  }

  isFormInValid(): boolean {
    const isInValid = _.any(this.topics, (t: any) => {
      return _.isFunction(t.isValid) && !t.isValid();
    });

    return isInValid;
  }

  navigateToNext = (): void => {
    this.roleIds = this.localSettings.keys.navigation.ids.getLocal;
    const ids = this.roleIds;
    const total: any = ids ? ids.length : 0;
    const stateParam = {
      id: this.stateParams.id
    };
    if (total === 0) {
      this.state.go('roles', { location: 'replace' });

      return;
    } else if (this.roleIndex < total) {
      stateParam.id = total === 1 && this.roleIndex !== 0 ? ids[this.roleIndex - 1] : ids[this.roleIndex];
    } else if (this.roleIndex === total) {
      stateParam.id = ids[this.roleIndex - 1];
    }

    const navKeyIndex = _.findIndex(this.navData.keys, (data: any) => {
      return data.value === this.stateParams.id.toString();
    });
    this.navData.keys.splice(navKeyIndex, 1);
    _.each(this.navData.keys, (item, index) => {
      item.key = (index + 1).toString();
    });
    const rowkey = _.first(this.navData.keys.filter(x => x.value === stateParam.id.toString())).key;

    this.state.go('role-details', {
      id: stateParam.id,
      roleName: '',
      rowKey: rowkey
    }, { location: 'replace' });
  };

  goToRole = (): void => {
    this.state.go('roles', { location: 'replace' });
  };

  init = (): void => {
    this.topics = {
      overview: {
        key: 'Overview',
        title: 'roleDetails.overview.title',
        component: RolesOverviewComponent,
        params: {
          viewData: {
            roleId: this.stateParams.id,
            canUpdateRole: this.canUpdateRole
          }
        }
      },
      tasks: {
        key: 'Tasks',
        title: 'roleDetails.tasks.title',
        component: RolesTasksComponent,
        params: {
          viewData: {
            roleId: this.stateParams.id,
            canUpdateRole: this.canUpdateRole
          }
        }
      },
      webPart: {
        key: 'WebPart',
        title: 'roleDetails.webPart.title',
        component: RolesWebPartComponent,
        params: {
          viewData: {
            roleId: this.stateParams.id,
            canUpdateRole: this.canUpdateRole
          }
        }
      },
      subject: {
        key: 'Subject',
        title: 'roleDetails.subject.title',
        component: RolesSubjectComponent,
        params: {
          viewData: {
            roleId: this.stateParams.id,
            canUpdateRole: this.canUpdateRole
          }
        }
      }
    };

    this.options = {
      topics: [
        this.topics.overview,
        this.topics.tasks,
        this.topics.webPart,
        this.topics.subject
      ]
    };
  };
}
