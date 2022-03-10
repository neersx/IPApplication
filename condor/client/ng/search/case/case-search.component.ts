import { ChangeDetectionStrategy, Component, Input, OnInit, ViewChild } from '@angular/core';
import { StateService } from '@uirouter/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { Hotkey } from 'angular2-hotkeys';
import { KeyBoardShortCutService } from 'core/keyboardshortcut.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { SearchTypeConfigProvider } from 'search/common/search-type-config.provider';
import { StepsPersistenceService } from 'search/multistepsearch/steps.persistence.service';
import { DueDateColumnsValidator } from 'search/presentation/search-presentation-due-date.validator';
import { SelectedColumn } from 'search/presentation/search-presentation.model';
import { SavedSearchComponent } from 'search/savedsearch/saved-search.component';
import { SaveOperationType, SaveSearchEntity } from 'search/savedsearch/saved-search.model';
import { SavedSearchService } from 'search/savedsearch/saved-search.service';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { Topic, TopicOptions } from 'shared/component/topics/ipx-topic.model';
import * as _ from 'underscore';
import { SearchPresentationPersistenceService } from './../presentation/search-presentation.persistence.service';
import { AttributesComponent, DataManagementComponent, DesignElementComponent, DetailsComponent, EventActionsComponent, NamesComponent, OtherDetailsComponent, PatentTermAdjustmentsComponent, ReferencesComponent, StatusComponent, TextComponent } from './case-search-topics';
import { CaseSavedSearchData, CaseSearchViewData } from './case-search.data';
import { CaseSearchService } from './case-search.service';
import { CaseTopicsDataService } from './case-topics-data.service';
import { DueDateFilterService } from './due-date/due-date-filter.service';
import { DueDateComponent } from './due-date/due-date.component';
import { DueDateCallbackParams, DueDateFormData } from './due-date/due-date.model';

@Component({
  selector: 'case-search',
  templateUrl: './case-search.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [DueDateColumnsValidator]
})

export class CaseSearchComponent implements OnInit {
  @Input() viewData: CaseSearchViewData;
  @Input() savedSearchData: CaseSavedSearchData;
  @ViewChild('multiStepsRef', { static: true }) multiStepRef;

  queryName: string;
  queryKey?: number;
  queryContextKey: number;
  isMultiStepMode: Boolean;
  hasDueDateColumn: Boolean;
  hasAllDateColumn: Boolean;
  topics: { [key: string]: Topic };
  options: TopicOptions;
  isExternal: Boolean;
  dueDateModalRef: BsModalRef;
  saveSearchModalRef: BsModalRef;
  dueDateFilter: any;
  dueDateFormData: DueDateFormData;
  isDueDatePoupOpen: Boolean;
  getEnterSrcControl: any;
  canCreateSavedSearch: Boolean;
  canUpdateSavedSearch: Boolean;
  canMaintainPublicSearch: Boolean;
  canDeleteSavedSearch: Boolean;
  isPublic: Boolean;
  menuItems: Array<any>;
  isDirty: Boolean;

  constructor(private readonly stateService: StateService, private readonly stepsPersistenceService: StepsPersistenceService,
    private readonly caseTopicsDataService: CaseTopicsDataService, private readonly keyBoardShortCutService: KeyBoardShortCutService,
    private readonly caseSearchService: CaseSearchService, private readonly modalService: IpxModalService,
    private readonly searchPresentationPersistenceService: SearchPresentationPersistenceService,
    private readonly dueDateColumnsValidator: DueDateColumnsValidator,
    private readonly savedSearchService: SavedSearchService,
    private readonly notificationService: NotificationService,
    public filterService: DueDateFilterService) {
    this.initShortcuts();
  }

  initShortcuts = () => {
    this.isDueDatePoupOpen = false;
    const hotkeys = [
      new Hotkey(
        'enter',
        (event, combo): boolean => {
          this.getEnterSrcControl = event.srcElement;
          if (this.getEnterSrcControl.getAttribute('name') !== 'quickSearch') {
            this.search(false);
          }

          return true;
        }, null, 'shortcuts.search', undefined, false)
    ];
    this.keyBoardShortCutService.add(hotkeys);
  };

  ngOnInit(): void {
    this.isExternal = this.viewData.isExternal;
    this.queryContextKey = this.viewData.queryContextKey;
    SearchTypeConfigProvider.getConfigurationConstants(this.queryContextKey);
    this.init();
    this.setDueDatePresentation();
    this.stepsPersistenceService.defaultTopicsData = this.caseTopicsDataService.getTopicsDefaultModel();
    if (this.savedSearchData) {
      this.dueDateFormData = this.savedSearchData.dueDateFormData;
      if (!this.dueDateFilter && this.dueDateFormData) {
        this.dueDateFilter = this.filterService.prepareFilter(this.dueDateFormData);
      }
      this.queryName = this.savedSearchData.queryName;
      this.isPublic = this.savedSearchData.isPublic;
      this.queryKey = this.savedSearchData.queryKey;
      this.stepsPersistenceService.steps = this.savedSearchData.steps;
      this.isMultiStepMode = this.stepsPersistenceService.steps.length > 1;
    } else {
      this.stepsPersistenceService.steps = null;
    }
    this.canCreateSavedSearch = this.viewData.canCreateSavedSearch;
    this.canUpdateSavedSearch = this.viewData.canUpdateSavedSearch;
    this.canMaintainPublicSearch = this.viewData.canMaintainPublicSearch;
    this.isDirty = false;
    this.canDeleteSavedSearch = this.viewData.canDeleteSavedSearch;
  }

  initializeMenuItems = () => {
    this.menuItems = [
      { id: 'saveas', text: 'caseSearch.SaveAs', icon: 'cpa-icon cpa-icon-floppy-o-edit', action: this.saveAs, disabled: this.isSaveAsDisabled() },
      { id: 'edit', text: 'caseSearch.EditSavedSearchDetails', icon: 'cpa-icon cpa-icon-pencil-square-o', action: this.editSavedSearchDetails, disabled: this.disableEditSaveSearch() },
      { id: 'delete', text: 'caseSearch.DeleteSavedSearch', icon: 'cpa-icon cpa-icon-trash', action: this.deleteSavedSearch, disabled: this.disableDeleteSaveSearch() }];
  };

  isFormDirty = () => {
    this.isDirty = false;
    _.each(this.topics, (t: any) => {
      if (_.isFunction(t.isDirty)) {
        if (t.isDirty()) {
          this.isDirty = true;
        }
      }
    });

    return this.isDirty;
  };

  saveAs = () => {
    const filterData = this.createFilterData();
    const searchPresentationData = this.searchPresentationPersistenceService.getSearchPresentationData();
    const selectedColumns = searchPresentationData ? searchPresentationData.selectedColumnsData : null;
    const updatePresentation = searchPresentationData ? true : false;

    this.openSaveSearch(filterData, selectedColumns, updatePresentation, SaveOperationType.SaveAs);
  };

  isSaveAsDisabled = () => {
    return !(this.queryKey && this.canCreateSavedSearch);
  };

  disableSaveSearch = (): Boolean => {
    return this.queryKey ? (this.isPublic ? !this.canMaintainPublicSearch : !this.canUpdateSavedSearch)
      : !this.canCreateSavedSearch;
  };

  disableEditSaveSearch = (): Boolean => {
    return !(this.queryKey && (this.isPublic ? this.canMaintainPublicSearch : this.canUpdateSavedSearch));
  };

  disableDeleteSaveSearch = (): Boolean => {
    if (!this.queryKey) {
      return true;
    }

    return !(this.isPublic ? this.canMaintainPublicSearch : this.canDeleteSavedSearch);
  };

  editSavedSearchDetails = (): any => {
    const filterData = this.createFilterData();
    const searchPresentationData = this.searchPresentationPersistenceService.getSearchPresentationData();
    const selectedColumns = searchPresentationData ? searchPresentationData.selectedColumnsData : null;
    const updatePresentation = searchPresentationData ? true : false;

    this.openSaveSearch(filterData, selectedColumns, updatePresentation, SaveOperationType.EditDetails);
  };

  deleteSavedSearch = (event: any): any => {
    this.notificationService
      .confirmDelete({
        message: 'caseSearch.presentationColumns.savedSearchDelete'
      })
      .then(() => {
        this.caseSearchService.DeletePresentation(this.queryKey).subscribe(res => {
          if (res) {
            this.stateService.go('casesearch', {
              queryKey: null,
              canEdit: null,
              returnFromCaseSearchResults: false
            });
          }
        });
      });
  };

  init = (): void => {
    this.topics = {
      references: {
        key: 'References',
        title: 'caseSearch.topics.references.title',
        component: ReferencesComponent,
        params: {
          viewData: {
            isExternal: this.isExternal,
            numberTypes: this.viewData.numberTypes,
            nameTypes: this.viewData.nameTypes
          }
        }
      },
      details: {
        key: 'Details',
        title: 'caseSearch.topics.details.title',
        component: DetailsComponent,
        params: {
          viewData: {
            isExternal: this.isExternal,
            allowMultipleCaseTypeSelection: this.viewData
              .allowMultipleCaseTypeSelection
          }
        }
      },
      text: {
        key: 'Text',
        title: 'caseSearch.topics.text.title',
        component: TextComponent,
        params: {
          viewData: {
            textTypes: this.viewData.textTypes
          }
        }
      },
      names: {
        key: 'Names',
        title: 'caseSearch.topics.names.title',
        component: NamesComponent,
        params: {
          viewData: {
            isExternal: this.isExternal,
            nameTypes: this.viewData.nameTypes,
            showCeasedNames: this.viewData.showCeasedNames
          }
        }
      },
      status: {
        key: 'Status',
        title: 'caseSearch.topics.status.title',
        component: StatusComponent,
        params: {
          viewData: {
            isExternal: this.isExternal
          }
        }
      },
      eventsActions: {
        key: 'eventsActions',
        title: 'caseSearch.topics.dates.title',
        component: EventActionsComponent,
        params: {
          viewData: {
            isExternal: this.isExternal,
            importanceOptions: this.viewData.importanceOptions,
            showEventNoteType: this.viewData.showEventNoteType,
            showEventNoteSection: this.viewData.showEventNoteSection
          }
        }
      },
      otherDetails: {
        key: 'otherDetails',
        title: 'caseSearch.topics.otherDetails.title',
        component: OtherDetailsComponent,
        params: {
          viewData: {
            isExternal: this.isExternal,
            entitySizes: this.viewData.entitySizes
          }
        }
      },
      attributes: {
        key: 'attributes',
        title: 'caseSearch.topics.attributes.title',
        component: AttributesComponent,
        params: {
          viewData: {
            isExternal: this.isExternal,
            attributes: this.viewData.attributes
          }
        }
      },
      dataManagement: {
        key: 'dataManagement',
        title: 'caseSearch.topics.dataManagement.title',
        component: DataManagementComponent,
        params: {
          viewData: {
            isExternal: this.isExternal,
            sentToCpaBatchNo: this.viewData.sentToCpaBatchNo
          }
        }
      }
    };

    if (this.viewData.isPatentTermAdjustmentTopicVisible) {
      Object.assign(this.topics, {
        patentTermAdjustments: {
          key: 'patentTermAdjustments',
          title: 'caseSearch.topics.patentTermAdjustments.title',
          component: PatentTermAdjustmentsComponent,
          params: {
            viewData: {}
          }
        }
      });
    }

    this.options = {
      topics: [
        this.topics.references,
        this.topics.details,
        this.topics.text,
        this.topics.names,
        this.topics.status,
        this.topics.eventsActions,
        this.topics.attributes,
        this.topics.otherDetails,
        this.topics.dataManagement
      ]
    };

    if (this.viewData.designElementTopicVisible) {
      const designElement = {
        key: 'designElement',
        title: 'caseSearch.topics.designElement.title',
        component: DesignElementComponent,
        params: {
          viewData: {
            isExternal: this.isExternal
          }
        }
      };

      this.topics.designElement = designElement;
      this.options.topics.push(designElement);
    }

    if (this.viewData.isPatentTermAdjustmentTopicVisible) {
      this.options.topics.splice(
        this.viewData.designElementTopicVisible
          ? this.options.topics.length - 2
          : this.options.topics.length - 1,
        0,
        this.topics.patentTermAdjustments
      );
    }
  };

  setDueDatePresentation = (): void => {
    const searchPresentationData = this.searchPresentationPersistenceService.getSearchPresentationData();

    if (searchPresentationData) {
      const selectedColumns = searchPresentationData.selectedColumns;
      const validator = this.dueDateColumnsValidator
        .validate(this.viewData.isExternal, selectedColumns);
      this.hasDueDateColumn = validator.hasDueDateColumn;
      this.hasAllDateColumn = validator.hasAllDateColumn;
    } else {
      this.hasDueDateColumn = this.viewData.hasDueDatePresentationColumn;
      this.hasAllDateColumn = this.viewData.hasAllDatePresentationColumn;
    }
  };

  isToggleDisabled = (): boolean => {
    return this.isMultiStepMode && (this.multiStepRef.steps != null && this.multiStepRef.steps.length > 1);
  };

  onToggle = (): void => {
    this.isMultiStepMode = !this.isMultiStepMode;
  };

  openDueDate = (): any => {
    const initialState = {
      existingFormData: this.dueDateFormData,
      hasDueDateColumn: this.hasDueDateColumn,
      hasAllDateColumn: this.hasAllDateColumn,
      importanceLevelOptions: this.viewData.importanceOptions
    };

    this.dueDateModalRef = this.modalService.openModal(DueDateComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-xl',
      initialState
    });

    if (this.dueDateModalRef) {
      this.isDueDatePoupOpen = true;
      this.dueDateModalRef.content.searchRecord.subscribe(
        (callbackParams: DueDateCallbackParams) => {
          this.dueDateFilter = callbackParams.filterCriteria;
          this.dueDateFormData = callbackParams.formData;
          this.dueDateModalRef.hide();
          this.isDueDatePoupOpen = false;
          if (!callbackParams.isModalClosed) {
            this.search(true);
          }
        }
      );
    }

    return this.dueDateModalRef;
  };

  persisCaseSearchData = (): any => {
    this.caseSearchService.caseSearchData = {
      viewData: this.viewData,
      savedSearchData: {
        queryKey: this.queryKey,
        isPublic: this.isPublic,
        queryName: this.savedSearchData ? this.savedSearchData.queryName : null,
        steps: this.multiStepRef.steps,
        dueDateFormData: this.dueDateFormData ? this.dueDateFormData : null,
        queryContext: this.queryContextKey
      }
    };
  };

  openPresentation = (): any => {
    const filterData = this.createFilterData();

    this.persisCaseSearchData();

    this.stateService.go('searchpresentation', {
      filter: filterData,
      queryKey: this.queryKey,
      isPublic: this.isPublic,
      queryName: this.savedSearchData ? this.savedSearchData.queryName : null,
      queryContextKey: this.queryContextKey
    });
  };

  reset = (): void => {
    _.each(this.topics, (t: any) => {
      if (_.isFunction(t.discard)) {
        t.discard();
      }
    });
    this.dueDateFormData = undefined;
  };

  createFilterData = (): any => {
    const caseFilterData = this.multiStepRef.getFilterCriteriaForSearch();

    return {
      searchRequest: caseFilterData,
      dueDateFilter: this.dueDateFilter
    };
  };

  search = (runSearch: Boolean): void => {
    if (!runSearch && (this.hasDueDateColumn || this.hasAllDateColumn) && !this.isDueDatePoupOpen) {
      this.openDueDate();

      return;
    }
    const filterData = this.createFilterData();

    this.persisCaseSearchData();
    const searchPresentationData = this.searchPresentationPersistenceService.getSearchPresentationData();

    this.stateService.go('search-results', {
      filter: filterData,
      queryKey: this.queryKey,
      searchQueryKey: true,
      rowKey: null,
      selectedColumns: searchPresentationData ? searchPresentationData.selectedColumnsData : null,
      queryContext: this.queryContextKey
    });
  };

  saveSearch = (): any => {
    const filterData = this.createFilterData();
    const searchPresentationData = this.searchPresentationPersistenceService.getSearchPresentationData();

    const selectedColumns = searchPresentationData ? searchPresentationData.selectedColumnsData : null;

    const updatePresentation = searchPresentationData ? true : false;

    if (this.queryKey) {
      this.executeSaveSearch(filterData, selectedColumns, updatePresentation);
    } else {
      this.openSaveSearch(filterData, selectedColumns, true, SaveOperationType.Add);
    }
  };

  openSaveSearch = (filterData: any, selectedColumns: Array<SelectedColumn>, updatePresentation: Boolean, type: SaveOperationType): any => {
    const initialState = {
      queryKey: (type === SaveOperationType.EditDetails || type === SaveOperationType.SaveAs ? this.queryKey : null),
      type,
      updatePresentation,
      selectedColumns,
      filter: filterData,
      queryContextKey: this.queryContextKey,
      canMaintainPublicSearch: this.viewData ? this.viewData.canMaintainPublicSearch : false
    };

    this.modalService.openModal(SavedSearchComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-lg',
      initialState
    });
  };

  executeSaveSearch = (filterData: any, selectedColumns: Array<SelectedColumn>, updatePresentation: Boolean): any => {
    const saveSearchEntity: SaveSearchEntity = {
      searchFilter: filterData,
      updatePresentation,
      selectedColumns,
      queryContext: this.queryContextKey
    };

    this.savedSearchService.saveSearch(saveSearchEntity, SaveOperationType.Update, this.queryKey, SearchTypeConfigProvider.savedConfig).subscribe(res => {
      if (res.success) {
        this.notificationService.success('saveMessage');
      }
    });
  };
}