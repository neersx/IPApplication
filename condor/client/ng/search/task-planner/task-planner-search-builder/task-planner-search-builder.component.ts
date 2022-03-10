import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { StateService, Transition } from '@uirouter/angular';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { Hotkey } from 'angular2-hotkeys';
import { KeyBoardShortCutService } from 'core/keyboardshortcut.service';
import { queryContextKeyEnum } from 'search/common/search-type-config.provider';
import { SelectedColumn } from 'search/presentation/search-presentation.model';
import { SearchPresentationPersistenceService } from 'search/presentation/search-presentation.persistence.service';
import { SavedSearchComponent } from 'search/savedsearch/saved-search.component';
import { SaveOperationType } from 'search/savedsearch/saved-search.model';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { Topic, TopicOptions } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { TaskPlannerService } from '../task-planner.service';
import { AdhocDateSearchBuilderTopic } from './adhoc-date-search-builder/adhoc-date-search-builder.component';
import { CasesCriteriaSearchBuilderTopic } from './cases-criteria-search-builder/cases-criteria-search-builder.component';
import { EventsActionsSearchBuilderTopic } from './events-actions-search-builder/events-actions-search-builder.component';
import { GeneralSearchBuilderTopic } from './general-search-builder/general-search-builder.component';
import { RemindersSearchBuilderTopic } from './reminders-search-builder/reminders-search-builder.component';
import { SavedTaskPlannerData, SearchBuilderViewData } from './search-builder.data';

@Component({
  selector: 'task-planner-search-builder',
  templateUrl: './task-planner-search-builder.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class TaskPlannerSearchBuilderComponent implements OnInit, AfterViewInit {
  @Input() viewData: SearchBuilderViewData;
  @Input() previousStateParams: { name: string, params: any };
  @Input() savedTaskPlannerData: SavedTaskPlannerData;

  topicOptions: TopicOptions;
  hasPreviousState: boolean;
  filterCriteria: any;
  formData: any;
  activeTabSequence: number;
  activeTabTitle: string;
  queryKey: number;
  menuItems: Array<any>;
  isPublic?: Boolean;

  constructor(private readonly stateService: StateService,
    private readonly keyBoardShortCutService: KeyBoardShortCutService,
    private readonly taskPlannerService: TaskPlannerService,
    private readonly transition: Transition,
    private readonly notificationService: NotificationService,
    private readonly modalService: IpxModalService,
    private readonly searchPresentationPersistenceService: SearchPresentationPersistenceService,
    private readonly notification: IpxNotificationService) {
    this.initShortcuts();
  }

  ngOnInit(): void {
    if (this.transition.from() && (this.transition.from().name === 'taskPlanner' || (this.transition.from().name === 'searchpresentation' && this.taskPlannerService.taskPlannerStateParam))) {
      this.hasPreviousState = true;
    }
    this.formData = this.previousStateParams && this.previousStateParams.params ? this.previousStateParams.params.formData : null;
    this.activeTabSequence = this.previousStateParams && this.previousStateParams.params ? this.previousStateParams.params.activeTabSeq : null;
    this.activeTabTitle = this.previousStateParams && this.previousStateParams.params ? this.previousStateParams.params.searchName : null;
    this.initializeTopics();
    this.queryKey = this.previousStateParams && this.previousStateParams.params ? this.previousStateParams.params.queryKey : null;
    if (this.savedTaskPlannerData.queryKey) {
      this.isPublic = this.savedTaskPlannerData.isPublic;
      this.queryKey = this.savedTaskPlannerData.queryKey;
      this.activeTabTitle = this.savedTaskPlannerData.queryName;
      this.hasPreviousState = true;
      this.activeTabSequence = this.taskPlannerService.taskPlannerStateParam ? this.taskPlannerService.taskPlannerStateParam.activeTabSeq : null;
      if (this.taskPlannerService.taskPlannerStateParam) {
        const taskPlannerStateParam = this.taskPlannerService.taskPlannerStateParam;
        taskPlannerStateParam.searchName = this.previousStateParams.params.searchName;
        taskPlannerStateParam.queryKey = +this.previousStateParams.params.queryKey;
        this.taskPlannerService.taskPlannerStateParam = taskPlannerStateParam;
      }
    }
    if (!this.queryKey) {
      this.activeTabTitle = null;
      this.hasPreviousState = false;
    }
    if (this.taskPlannerService.taskPlannerStateParam) {
      const taskPlannerParam = this.taskPlannerService.taskPlannerStateParam;
      taskPlannerParam.isPicklistSearch = this.previousStateParams.params.isPicklistSearch;
      this.taskPlannerService.taskPlannerStateParam = taskPlannerParam;
    }
  }

  ngAfterViewInit(): void {
    setTimeout(() => {
      if (this.taskPlannerService.isSavedSearchDeleted) {
        this.clear();
        this.taskPlannerService.isSavedSearchDeleted = false;
      }
      this.setFormPristine();
    }, 0);
  }

  clear(): void {
    _.each(this.topicOptions.topics, (t: any) => {
      if (_.isFunction(t.clear)) {
        t.clear();
      }
    });
  }

  saveButtonDisabled(): boolean {
    let result = true;
    if (this.taskPlannerService.taskPlannerStateParam && this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearch) {
      result = this.queryKey ? this.isPublic ? !(this.taskPlannerService.taskPlannerStateParam.maintainPublicSearch && this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.update)
        : !this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.update
        : !(this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.insert || this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.update);
    }

    return result;
  }

  canSearch(): boolean {
    return this.isFormValid();
  }

  initializeMenuItems = () => {
    this.menuItems = [
      { id: 'saveas', text: 'taskPlanner.SaveAs', icon: 'cpa-icon cpa-icon-floppy-o-edit', action: this.saveAs, disabled: this.isSaveAsDisabled() },
      { id: 'edit', text: 'taskPlanner.EditSavedSearchDetails', icon: 'cpa-icon cpa-icon-pencil-square-o', action: this.editTaskPlannerSavedSearch, disabled: this.disableEditTaskplannerSaveSearch() },
      { id: 'delete', text: 'taskPlanner.DeleteSavedSearch', icon: 'cpa-icon cpa-icon-trash', action: this.deleteSavedSearch, disabled: this.disableDeleteSaveSearch() }];
  };

  disableDeleteSaveSearch = (): Boolean => {
    if (!this.queryKey) {
      return true;
    }

    return this.taskPlannerService.taskPlannerStateParam ?
      !(this.isPublic ? this.taskPlannerService.taskPlannerStateParam.maintainPublicSearch && this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.delete :
        this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.delete) : true;
  };

  deleteSavedSearch = (): any => {
    this.notificationService
      .confirmDelete({
        message: 'caseSearch.presentationColumns.savedSearchDelete'
      })
      .then(() => {
        this.taskPlannerService.DeleteSavedSearch(this.queryKey).subscribe(res => {
          if (res) {
            this.taskPlannerService.isSavedSearchDeleted = true;
            this.stateService.go('taskPlannerSearchBuilder', {
              queryKey: null,
              canEdit: null,
              returnFromCaseSearchResults: false
            });
          } else {
            this.notification.openAlertModal('taskPlanner.deleteTitle', 'taskPlanner.deleteMeassage');
          }
        });
      });
  };

  saveAs = () => {
    const filter = this.getFormData();
    const searchPresentationData = this.searchPresentationPersistenceService.getSearchPresentationData();
    const selectedColumns = searchPresentationData ? searchPresentationData.selectedColumnsData : null;
    const updatePresentation = searchPresentationData ? true : false;

    this.openSaveSearch(filter.filterCriteria, selectedColumns, updatePresentation, SaveOperationType.SaveAs);
  };

  editTaskPlannerSavedSearch = (): any => {
    const filterData = this.getFormData();
    const searchPresentationData = this.searchPresentationPersistenceService.getSearchPresentationData();
    const selectedColumns = searchPresentationData ? searchPresentationData.selectedColumnsData : null;
    const updatePresentation = searchPresentationData ? true : false;

    this.openSaveSearch(filterData.filterCriteria, selectedColumns, updatePresentation, SaveOperationType.EditDetails);
  };

  disableEditTaskplannerSaveSearch = (): Boolean => {
    let result = true;
    if (this.taskPlannerService.taskPlannerStateParam && this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearch) {
      result = !(this.queryKey && (this.isPublic ? this.taskPlannerService.taskPlannerStateParam.maintainPublicSearch && this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.update : this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.update));
    }

    return result;
  };

  isSaveAsDisabled = () => {
    return !(this.queryKey && this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.insert);
  };

  updateTaskPlannerSearch(filterData: any, selectedColumns: Array<SelectedColumn>, updatePresentation: Boolean, type: SaveOperationType): void {
    if (this.queryKey) {
      const saveSearchEntity = {
        searchFilter: filterData,
        updatePresentation,
        selectedColumns,
        queryContext: queryContextKeyEnum.taskPlannerSearch,
        queryKey: this.queryKey
      };
      this.taskPlannerService.updateTaskPlannerSearch(saveSearchEntity, saveSearchEntity.queryKey).subscribe(res => {
        if (res.success) {
          this.notificationService.success('saveMessage');
          this.setFormPristine();
        }
      });
    }
  }

  setFormPristine = () => {
    _.each(this.topicOptions.topics, (t: any) => {
      if (_.isFunction(t.setPristine)) {
        t.setPristine();
      }
    });
  };

  saveSearch(): void {
    const filter = this.getFormData();
    const searchPresentationData = this.searchPresentationPersistenceService.getSearchPresentationData();
    const selectedColumns = searchPresentationData ? searchPresentationData.selectedColumnsData : null;
    const updatePresentation = searchPresentationData ? true : false;
    if (this.queryKey) {
      this.updateTaskPlannerSearch(filter.filterCriteria, selectedColumns, updatePresentation, SaveOperationType.Update);
    } else {
      this.openSaveSearch(filter.filterCriteria, selectedColumns, updatePresentation, SaveOperationType.Add);
    }
  }

  openSaveSearch = (filterData: any, selectedColumns: Array<SelectedColumn>, updatePresentation: Boolean, type: SaveOperationType): any => {
    const initialState = {
      queryKey: (type === SaveOperationType.EditDetails || type === SaveOperationType.SaveAs ? this.queryKey : null),
      type,
      updatePresentation,
      selectedColumns,
      filter: filterData,
      queryContextKey: +queryContextKeyEnum.taskPlannerSearch,
      canMaintainPublicSearch: this.taskPlannerService.taskPlannerStateParam.maintainPublicSearch
    };

    this.modalService.openModal(SavedSearchComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-lg',
      initialState
    });
  };

  search(): void {
    const data = this.getFormData();
    const isFormDirty = this.isFormDirty();
    if (_.some(data)) {
      const selectedColumns = this.previousStateParams && this.previousStateParams.params ? this.previousStateParams && this.previousStateParams.params.selectedColumns : null;
      this.stateService.go('taskPlanner', {
        filterCriteria: data.filterCriteria,
        formData: data.formData, searchBuilder: true,
        isFormDirty,
        selectedColumns, activeTabSeq: this.activeTabSequence,
        queryKey: this.queryKey, searchName: this.activeTabTitle
      });
    }
  }

  private readonly initShortcuts = () => {
    const hotkeys = [
      new Hotkey(
        'enter',
        (event, combo): boolean => {
          if (this.canSearch()) {
            this.search();
          }

          return true;
        }, null, 'shortcuts.search', undefined, false)
    ];
    this.keyBoardShortCutService.add(hotkeys);
  };

  private getFormData(): any {
    if (!this.topicOptions) {
      return null;
    }
    const data = { filterCriteria: { searchRequest: {} as any }, formData: {} };
    _.each(this.topicOptions.topics, (t: any) => {
      if (_.isFunction(t.getFormData)) {
        const topicData = t.getFormData();
        _.extend(data.filterCriteria.searchRequest, topicData.searchRequest);
        _.extend(data.formData, topicData.formData);
      }
    });
    if (data.filterCriteria.searchRequest.includeAdhocDate) {
      _.extend(data.filterCriteria.searchRequest.include, data.filterCriteria.searchRequest.includeAdhocDate);
    }

    return data;
  }

  private isFormValid(): boolean {
    let isValid = true;
    _.each(this.topicOptions.topics, (t: any) => {
      if (_.isFunction(t.isValid)) {
        if (!t.isValid()) {
          isValid = false;
        }
      }
    });

    return isValid;
  }

  private isFormDirty(): boolean {
    const isDirty = _.any(this.topicOptions.topics, (t: any) => {
      return _.isFunction(t.isDirty) && t.isDirty();
    });

    return isDirty;
  }

  private initializeTopics(): void {
    this.viewData.formData = this.formData;
    if (this.savedTaskPlannerData.formData) {
      const savedTaskPlannerFormData = this.buildFormData();
      this.viewData.formData = this.previousStateParams && this.previousStateParams.params && this.viewData.formData ? _.extend(savedTaskPlannerFormData, this.viewData.formData) : savedTaskPlannerFormData;
    }
    const topics: Array<Topic> = [
      new GeneralSearchBuilderTopic({ viewData: this.viewData }),
      new CasesCriteriaSearchBuilderTopic({ viewData: this.viewData }),
      new EventsActionsSearchBuilderTopic({ viewData: this.viewData }),
      new RemindersSearchBuilderTopic({ viewData: this.viewData }),
      new AdhocDateSearchBuilderTopic({ viewData: this.viewData })
    ];

    this.topicOptions = { topics, actions: [] };
  }

  buildFormData(): any {
    const formData = {};
    _.each(this.savedTaskPlannerData.formData, (t: any) => {
      formData[t.topicKey] = t.formData;
    });

    return formData;
  }

  openPresentation = (): any => {
    const filterData = this.getFormData();

    this.stateService.go('searchpresentation', {
      filter: filterData,
      activeTabSeq: this.activeTabSequence,
      queryKey: this.previousStateParams && this.previousStateParams.params ? this.previousStateParams.params.queryKey : null,
      isPublic: false,
      queryName: this.activeTabTitle,
      queryContextKey: queryContextKeyEnum.taskPlannerSearch
    });
  };
}
