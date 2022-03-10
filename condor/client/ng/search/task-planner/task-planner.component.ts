import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Input,
  OnDestroy,
  OnInit,
  ViewChild
} from '@angular/core';
import { AttachmentPopupService } from 'common/attachments/attachments-popup/attachment-popup.service';
import { AppContextService } from 'core/app-context.service';
import { LocalSettings } from 'core/local-settings';
import { QuickNavModel, RightBarNavService } from 'rightbarnav/rightbarnav.service';
import { Observable, of } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import {
  TaskPlannerPreferencesComponent
} from '../../rightbarnav/taskplannerpreferences/task-planner-preferences.component';
import { TaskPlannerPersistenceService } from './task-planner-persistence.service';
import {
  TaskPlannerSearchResultComponent
} from './task-planner-search-result/task-planner-search-result.component';
import { QueryData, TaskPlannerPreferenceModel, TaskPlannerViewData, UserPreferenceViewData } from './task-planner.data';
import { TaskPlannerService } from './task-planner.service';
@Component({
  selector: 'app-task-planner',
  templateUrl: './task-planner.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [AttachmentPopupService]
})
export class TaskPlannerComponent implements OnInit, OnDestroy {

  selectedTab: QueryData;
  tabs: any;
  selectedSavedSearch: Array<QueryData>;
  activeTabSeq = 1;
  persistedTabs: any;
  canInsertTaskPlannerSearch: boolean;
  isExternal: boolean;
  @Input() viewData: TaskPlannerViewData;
  @ViewChild(TaskPlannerSearchResultComponent, { static: true }) searchResult: TaskPlannerSearchResultComponent;

  constructor(
    private readonly cdr: ChangeDetectorRef,
    private readonly persistenceService: TaskPlannerPersistenceService,
    private readonly service: TaskPlannerService,
    public rightBarNavService: RightBarNavService,
    private readonly appContextService: AppContextService,
    private readonly localSettings: LocalSettings,
    private readonly ipxNotificationService: IpxNotificationService
  ) {
    this.checkStateParams();
    this.tabs = [];
    this.taskPlannerExtendedParam = this.taskPlannerExtendedParam.bind(this);
  }

  ngOnInit(): void {

    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe(ctx => {
        this.isExternal = ctx.user.isExternal;
        this.setContextNavigation();
        this.cdr.markForCheck();
      });

    this.initializeTab();
    this.persistInitialTabs();
    const tabIndex = this.activeTabSeq - 1;
    this.searchResult.viewData = this.viewData;
    const params = this.service.previousStateParam;
    this.canInsertTaskPlannerSearch = this.viewData.maintainTaskPlannerSearchPermission.insert;
    if (this.service.isCustomSearch()) {
      if (params.searchQuery) {
        this.searchResult.onSavedSearchChange(params.searchQuery);
      }
      this.selectedSavedSearch[tabIndex] = { searchName: '', key: null, tabSequence: this.activeTabSeq };
      this.tabs[tabIndex] = { ...this.selectedSavedSearch[tabIndex] };
      this.persistenceService.clearTabData(this.activeTabSeq);
    } else {
      if (this.service.previousStateParam && this.service.previousStateParam.queryKey) {
        const queryExists = _.first(this.persistedTabs.filter(x => x.queryKey === this.service.previousStateParam.queryKey));
        if (!queryExists) {
          this.selectedSavedSearch[tabIndex] = { searchName: this.service.previousStateParam.searchName, key: this.service.previousStateParam.queryKey, tabSequence: this.activeTabSeq };
          this.tabs[tabIndex] = { ...this.selectedSavedSearch[tabIndex] };
        }
      } else {
        this.selectedSavedSearch[tabIndex] = { ...this.tabs[tabIndex] };
      }
    }
    this.selectTab(this.selectedSavedSearch[tabIndex]);
    this.searchResult.presistTaskPlannerData();
    this.selectedTab = this.selectedSavedSearch[tabIndex];
    this.searchResult.togglePreview(this.localSettings.keys.taskPlanner.showPreview.getLocal);
  }

  ngOnDestroy(): void {
    if (!this.isRedirected) {
      this.persistenceService.clear();
    }
  }

  isRedirected = (event): boolean => {
    return event ? true : false;
  };

  checkStateParams(): void {
    const preStateParam = this.service.previousStateParam;
    if (preStateParam && preStateParam.searchBuilder && this.service.previousStateParam.queryKey) {
      this.persistedTabs = [...this.persistenceService.getTabs()];
      let updateTabName: any = {};
      updateTabName = _.first(this.persistedTabs.filter(x => x.queryKey === this.service.previousStateParam.queryKey));
      if (updateTabName && this.service.previousStateParam.searchName) {
        updateTabName.searchName = this.service.previousStateParam.searchName;
      }
    } else {
      this.persistenceService.clear();
    }
  }

  initializeTab(): void {
    const preStateParam = this.service.previousStateParam;
    this.activeTabSeq = preStateParam && preStateParam.activeTabSeq ? preStateParam.activeTabSeq : 1;
    this.checkStateParams();

    if (preStateParam && preStateParam.searchBuilder && !this.service.taskPlannerTabs) {
      this.tabs = [{ searchName: '', tabSequence: this.activeTabSeq }];
      this.selectedSavedSearch = [];
    } else {
      this.tabs = [...this.service.taskPlannerTabs];
      this.selectedSavedSearch = [...this.service.taskPlannerTabs];
    }
  }

  persistInitialTabs(): void {
    let tabsData = this.tabs;
    if (this.service.previousStateParam && this.service.previousStateParam.searchBuilder) {
      tabsData = this.persistedTabs;
      this.persistenceService.saveTabs(tabsData);
      this.persistenceService.getPersistedTabIntoQueryData(this.tabs);
      this.selectedSavedSearch = [...this.tabs];
    }
    this.persistenceService.persistInitialTabs(this.tabs);
  }

  selectTab = (tab: QueryData, tabIndex = 0, tabClicked = false) => {
    if (this.selectedTab && this.selectedTab === tab) {
      return;
    }
    if (this.searchResult.hasAnyNoteOrCommentChanged()) {
      const modalRef = this.ipxNotificationService.openConfirmationModal('modal.discardchanges.title', 'taskPlanner.discardMessage', 'modal.discardchanges.discardButton', 'modal.discardchanges.cancel');
      modalRef.content.confirmed$.subscribe(() => {
        this.searchResult.dirtyNotesAndComments.clear();
        modalRef.hide();
        this.openTab(tab, tabIndex, tabClicked);
      });
    } else {
      this.openTab(tab, tabIndex, tabClicked);
    }
  };

  private readonly openTab = (tab: QueryData, tabIndex: number, tabClicked: boolean) => {

    if (tab && !tab.tabSequence) {
      tab.tabSequence = tabIndex + 1;
    }
    if (tab) {
      this.service.isSavedSearchChangeEvent = true;
      this.persistenceService.changedTabSeq$.next({ activeTab: this.activeTabSeq, nextSequence: tab.tabSequence, clicked: tabClicked });
      this.activeTabSeq = tab.tabSequence;
      this.resetEmptyTab(this.selectedTab);
      this.selectedTab = tab;
      this.searchResult.initializeTab(tab, true);
      this.cdr.markForCheck();
    }
  };

  resetEmptyTab(tab: QueryData): void {
    if (!tab) {
      return;
    }
    const emptyIndex = this.selectedSavedSearch.findIndex(x => x === null);
    if (emptyIndex > -1) {
      this.selectedSavedSearch[emptyIndex] = tab;
      this.cdr.detectChanges();
    }
  }

  onChangeQueryKey = (event: any, tabSequence: number) => {
    if (!event) {
      return;
    }

    if (!this.selectedSavedSearch[tabSequence - 1]) {
      return;
    }

    const tab = { ...event, ...{ tabSequence } };
    this.selectedSavedSearch[tabSequence - 1] = tab;
    this.searchResult.onSavedSearchChange(tab);
  };

  trackBy = (index: number, item: any) => {
    return index;
  };

  taskPlannerExtendedParam(): any {
    return {
      maintainPublicSearch: this.viewData.maintainPublicSearch,
      canUpdateSavedSearch: this.viewData.maintainTaskPlannerSearchPermission.update
    };
  }

  setStoreOnToggle(event: Event): void {
    this.localSettings.keys.taskPlanner.showPreview.setLocal(event);
    this.searchResult.togglePreview(event ? true : false);
    this.cdr.markForCheck();
  }

  private readonly setContextNavigation = () => {
    const context: any = {};
    if (!this.isExternal) {
      context.contextTaskPlanner = new QuickNavModel(TaskPlannerPreferencesComponent, {
        id: 'contextTaskPlanner',
        title: 'taskPlanner.contextMenu.preferencesComponentTitle',
        icon: 'cpa-icon-cog',
        tooltip: 'taskPlanner.contextMenu.preferencesMenuTooltip',
        resolve: {
          viewData: (): Observable<UserPreferenceViewData> => {
            return this.service.getUserPreferenceViewData();
          }
        }
      });
    }

    this.rightBarNavService.registercontextuals(context);
  };
}