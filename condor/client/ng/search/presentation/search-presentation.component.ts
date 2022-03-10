import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, DoCheck, ElementRef, Input, KeyValueDiffer, KeyValueDiffers, OnInit, Renderer2, ViewChild } from '@angular/core';
import { StateService } from '@uirouter/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { Hotkey } from 'angular2-hotkeys';
import { AppContextService } from 'core/app-context.service';
import { KeyBoardShortCutService } from 'core/keyboardshortcut.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject, forkJoin, of } from 'rxjs';
import { delay, map, take } from 'rxjs/operators';
import { queryContextKeyEnum, SearchTypeConfigProvider } from 'search/common/search-type-config.provider';
import { SavedSearchComponent } from 'search/savedsearch/saved-search.component';
import { SaveOperationType, SaveSearchEntity } from 'search/savedsearch/saved-search.model';
import { SavedSearchService } from 'search/savedsearch/saved-search.service';
import { SearchColumnMaintenanceComponent } from 'search/searchcolumns/search-column.maintenance.component';
import { SearchColumnState } from 'search/searchcolumns/search-columns.model';
import { TaskPlannerViewData } from 'search/task-planner/task-planner.data';
import { TaskPlannerService } from 'search/task-planner/task-planner.service';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { HostChildComponent } from 'shared/component/page/host-child-component';
import { DragDropBaseComponent } from 'shared/directives/drag-drop-base.component';
import * as _ from 'underscore';
import { CaseSearchService } from '../case/case-search.service';
import { DueDateComponent } from '../case/due-date/due-date.component';
import { DueDateCallbackParams, DueDateFormData } from '../case/due-date/due-date.model';
import { DueDateColumnsValidator } from './search-presentation-due-date.validator';
import { PresentationColumnView, SavedPresentationQuery, SearchContextEnum, SearchPresentationData, SearchPresentationViewData, SelectedColumn } from './search-presentation.model';
import { SearchPresentationPersistenceService } from './search-presentation.persistence.service';
import { SearchPresentationService } from './search-presentation.service';

@Component({
  selector: 'search-presentation',
  templateUrl: './search-presentation.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [DueDateColumnsValidator]
})
export class SearchPresentationComponent extends DragDropBaseComponent implements OnInit, AfterViewInit, DoCheck, HostChildComponent {
  @Input() viewData: SearchPresentationViewData;
  @Input() taskPlannerViewData: TaskPlannerViewData;

  @Input() stateParams: {
    queryKey: number,
    isPublic: Boolean,
    filter: any,
    queryName: string,
    q: string,
    levelUpState: string,
    selectedColumns: Array<SelectedColumn>,
    queryContextKey: number,
    activeTabSeq: number
  };

  hasPreviousState = false;
  gridOptions: IpxGridOptions;
  selectedCount: Number;
  sortOrder: Array<Number>;
  useDefaultPresentation: Boolean;
  availableColumns = new BehaviorSubject<Array<PresentationColumnView>>([]);
  availableColumnsMultipleSelelction: Array<any> = [];
  selectedColumnsMultipleSelelction = Array<PresentationColumnView>();
  availableColumns$ = this.availableColumns.asObservable();
  selectedColumns = Array<PresentationColumnView>();
  availableColumnsStore = Array<PresentationColumnView>();
  availableColumnsForSearch = Array<PresentationColumnView>();
  getSelectedColumnsOnly = false;
  searchTerm?: string;
  queryName?: string;
  savedPresentationQueries = Array<SavedPresentationQuery>();
  noRecordsFound: Boolean;
  copyPresentationQuery: any;
  queryKey: Number;
  hasDueDateColumn: Boolean;
  hasAllDateColumn: Boolean;
  dueDateModalRef: BsModalRef;
  dueDateFilter: any;
  dueDateFormData: DueDateFormData;
  isDueDatePoupOpen: Boolean;
  selectedColumnsData: Array<SelectedColumn> = [];
  queryContextKey: Number;
  canCreateSavedSearch: Boolean;
  canUpdateSavedSearch: Boolean;
  canMaintainPublicSearch: Boolean;
  menuItems: Array<any>;
  hostedMenuOptions: Array<any>;
  userHasDefaultPresentation: Boolean;
  refreshPresentation: Boolean;
  canDeleteSavedSearch: Boolean;
  additionalStateParams: any;
  isGroupingAllowed = false;
  searchColumnModalRef: BsModalRef;
  searchColumnState = SearchColumnState;
  isAvailableColumnEdit = false;
  upatedColumnKey?: Number;
  canEditColumn: Boolean;
  isExternal: Boolean;
  isDefaultOrRevertPresentation = false;
  droppedItem: any;
  levelUpTooltip: string;
  activeTabSeq: number;
  isSelectedColumnAttributeChanged = false;

  onChangeAction: () => void;
  onNavigationAction: (e: any) => void;
  isShowingHeader = false;
  private readonly differ: any;
  isTaskPlannerPresentation = false;

  constructor(private readonly stateService: StateService, public renderer: Renderer2,
    private readonly service: SearchPresentationService, private readonly cdRef: ChangeDetectorRef,
    private readonly caseSearchService: CaseSearchService, private readonly modalService: IpxModalService, private readonly keyBoardShortCutService: KeyBoardShortCutService,
    private readonly searchPresentationService: SearchPresentationPersistenceService,
    private readonly dueDateColumnsValidator: DueDateColumnsValidator,
    differs: KeyValueDiffers,
    private readonly savedSearchService: SavedSearchService,
    private readonly notificationService: NotificationService,
    private readonly appContextService: AppContextService,
    private readonly taskPlannerService: TaskPlannerService,
    private readonly notification: IpxNotificationService
  ) {
    super(renderer);
    this.differ = differs.find({}).create();
    this.initShortcuts();
  }

  initShortcuts = () => {
    this.isDueDatePoupOpen = false;
    const hotkeys = [
      new Hotkey(
        'enter',
        (event, combo): boolean => {
          const enterSrcControl: any = event.srcElement;
          if (enterSrcControl.getAttribute('name') !== 'quickSearch') {
            this.executeSearch();
          }

          return true;
        }, null, 'shortcuts.search', undefined, false)
    ];
    this.keyBoardShortCutService.add(hotkeys);
  };

  ngOnInit(): void {
    this.activeTabSeq = this.stateParams.activeTabSeq ? this.stateParams.activeTabSeq : 1;
    if (this.stateParams.levelUpState
      && (this.stateParams.levelUpState === 'search-results'
        || this.stateParams.levelUpState === 'taskPlanner')) {
      this.hasPreviousState = true;
    }
    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe(ctx => {
        this.isExternal = ctx.user.isExternal;

      });
    this.queryKey = this.viewData.queryKey;
    this.queryContextKey = +this.viewData.queryContextKey;
    SearchTypeConfigProvider.getConfigurationConstants(this.queryContextKey);
    this.queryName = this.queryKey ? this.viewData.queryName : null;
    this.canCreateSavedSearch = this.viewData.canCreateSavedSearch;
    this.canUpdateSavedSearch = this.viewData.canUpdateSavedSearch;
    this.canMaintainPublicSearch = this.viewData.canMaintainPublicSearch;
    this.userHasDefaultPresentation = this.viewData.userHasDefaultPresentation;
    this.canDeleteSavedSearch = this.viewData.canDeleteSavedSearch;
    const formData = this.stateParams && this.stateParams.filter ? this.stateParams.filter.formData : null;
    this.additionalStateParams = { q: this.viewData.q, formData, levelUpClicked: true };
    this.initializePresentationData();
    this.maintenanaceColumnSecurity();
    this.setGroupingAllowed();
    this.gridOptions = this.buildGridOptions();
    this.levelUpTooltip = this.hasTaskPlannerContext() ? 'taskPlanner.searchBuilder.backToTaskPlanner' : 'caseview.backToSearchResults';
  }

  ngAfterViewInit(): void {
    this.buildHostedMenuOptions();

    if (this.searchPresentationService.getSearchPresentationData(this.activeTabSeq.toString())) {
      this.copyPresentationQuery = this.searchPresentationService.getSearchPresentationData(this.activeTabSeq.toString()).copyPresentationQuery; // Need to be removed once ngModelChange issue is fixed in typeahead.
    }
  }

  maintenanaceColumnSecurity(): void {
    this.canEditColumn = !this.isExternal ? this.viewData.canMaintainColumns
      : false;
  }

  refreshAvailableColumns(): void {
    this.isAvailableColumnEdit = true;
    this.gridOptions._search();
    this.isAvailableColumnEdit = false;
    this.availableColumnsMultipleSelelction = [];
  }

  buildHostedMenuOptions = () => {
    this.hostedMenuOptions = [
      { id: 'default', text: 'caseSearch.MakeThisMyDefault', icon: 'cpa-icon cpa-icon-check', action: this.makeDefaultPresentation },
      { id: 'revert', text: 'caseSearch.revertToStandardDefault', icon: 'cpa-icon cpa-icon-revert', action: this.revertToDefault }
    ];
  };

  initializeMenuItems = () => {
    this.menuItems = [];
    this.menuItems.push(
      { id: 'edit', text: 'caseSearch.EditSavedSearchDetails', icon: 'cpa-icon cpa-icon-pencil-square-o', action: this.editSavedSearchDetails, disabled: this.disableEditSaveSearch() },
      { id: 'saveas', text: 'caseSearch.SaveAs', icon: 'cpa-icon cpa-icon-floppy-o-edit', action: this.saveAs, disabled: this.isSaveAsDisabled() },
      { id: 'default', text: 'caseSearch.MakeThisMyDefault', icon: 'cpa-icon cpa-icon-check', action: this.makeDefaultPresentation, disabled: this.useDefaultPresentation },
      { id: 'revert', text: 'caseSearch.revertToStandardDefault', icon: 'cpa-icon cpa-icon-revert', action: this.revertToDefault, disabled: !this.userHasDefaultPresentation },
      { id: 'delete', text: 'caseSearch.DeleteSavedSearch', icon: 'cpa-icon cpa-icon-trash', action: this.deleteSavedSearch, disabled: this.disableDeleteSaveSearch() }
    );

  };

  isSaveAsDisabled = () => {
    if (this.hasTaskPlannerContext()) {
      return this.taskPlannerService.taskPlannerStateParam ? !(this.queryKey && this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.insert) : true;
    }

    return !(this.viewData.queryKey && this.canCreateSavedSearch);
  };

  goToMaintainColumns = () => {
    const url = '#/search/columns?queryContextKey=' + this.queryContextKey;
    window.open(url, '_blank');
  };

  openModal = (column: any, state: string) => {
    this.isAvailableColumnEdit = true;
    const initialState = {
      columnId: column.columnKey,
      queryContextKey: +this.queryContextKey,
      states: state,
      appliesToInternal: true,
      displayFilterBy: false,
      displayNavigation: false
    };
    this.searchColumnModalRef = this.modalService.openModal(SearchColumnMaintenanceComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-xl',
      initialState
    });
    this.searchColumnModalRef.content.searchColumnRecord.subscribe(
      (callbackParams: any) => {
        if (callbackParams.runSearch) {
          this.gridOptions._search();
          this.isAvailableColumnEdit = false;
          this.availableColumnsMultipleSelelction = [];
          if (callbackParams.updatedId) {
            this.upatedColumnKey = callbackParams.updatedId;
          }
          this.cdRef.markForCheck();
        }
        this.searchColumnModalRef.hide();
      }
    );
  };

  saveAs = () => {
    this.populateSelectedColumns();
    const filterData = this.hasTaskPlannerContext() ? (this.viewData.filter.filterCriteria.searchRequest && !this.viewData.filter.filterCriteria.searchRequest.actions) ? null : this.viewData.filter.filterCriteria : this.viewData.filter;
    const selectedColumns = this.useDefaultPresentation ? null : this.selectedColumnsData;

    this.openSaveSearch(filterData, selectedColumns, SaveOperationType.SaveAs);
  };

  makeDefaultPresentation = () => {
    this.populateSelectedColumns();
    const saveSearchEntity: SaveSearchEntity = {
      searchFilter: this.viewData.filter,
      updatePresentation: true,
      queryContext: this.queryContextKey,
      selectedColumns: this.selectedColumnsData
    };
    this.service.makeMyDefaultPresentation(saveSearchEntity).subscribe(res => {
      if (res) {
        this.isDefaultOrRevertPresentation = true;
        this.userHasDefaultPresentation = true;
        this.reloadPresentation();
        this.isSelectedColumnAttributeChanged = true;
      }
    });
  };

  revertToDefault = () => {
    this.service.revertToDefault(this.queryContextKey).subscribe(res => {
      if (res) {
        this.isDefaultOrRevertPresentation = true;
        this.queryKey = null;
        this.userHasDefaultPresentation = false;
        this.reloadPresentation();
        this.isSelectedColumnAttributeChanged = true;
      }
    });
  };

  reloadPresentation = () => {
    this.selectedColumns = [];
    this.refreshPresentation = true;
    this.gridOptions._search();
    this.notificationService.success('saveMessage');
  };

  disableSaveSearch = (): Boolean => {
    let result = true;
    if (+this.viewData.queryContextKey === queryContextKeyEnum.taskPlannerSearch) {
      if (this.taskPlannerViewData && this.taskPlannerViewData.maintainTaskPlannerSearch) {
        result = this.queryKey ? this.taskPlannerViewData.isPublic ? !(this.taskPlannerViewData.maintainPublicSearch && this.taskPlannerViewData.maintainTaskPlannerSearchPermission.update)
          : !this.taskPlannerViewData.maintainTaskPlannerSearchPermission.update
          : !this.taskPlannerViewData.maintainTaskPlannerSearchPermission.insert;
      }
    } else {
      result = this.viewData.queryKey ? (this.viewData.isPublic ? !this.canMaintainPublicSearch : !this.canUpdateSavedSearch)
        : !this.canCreateSavedSearch;
    }

    return result;
  };

  disableEditSaveSearch = (): Boolean => {
    let result = true;
    result = this.hasTaskPlannerContext() ? this.taskPlannerService.taskPlannerStateParam ?
      !(this.queryKey && (this.taskPlannerViewData.isPublic ?
        this.taskPlannerService.taskPlannerStateParam.maintainPublicSearch && this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.update :
        this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.update)) : true :
      !(this.viewData.queryKey && (this.viewData.isPublic ? this.canMaintainPublicSearch : this.canUpdateSavedSearch));

    return result;
  };

  disableDeleteSaveSearch = (): Boolean => {
    let result = true;
    if (!this.queryKey) {
      return result;
    }
    result = this.hasTaskPlannerContext() ? this.taskPlannerService.taskPlannerStateParam ?
      !(this.taskPlannerViewData.isPublic ?
        this.taskPlannerService.taskPlannerStateParam.maintainPublicSearch && this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.delete :
        this.taskPlannerService.taskPlannerStateParam.maintainTaskPlannerSearchPermission.delete) : true :
      !(this.viewData.isPublic ? this.canMaintainPublicSearch : this.canDeleteSavedSearch);

    return result;
  };

  editSavedSearchDetails = (): any => {
    this.populateSelectedColumns();
    const filterData = this.hasTaskPlannerContext() ? (this.viewData.filter.filterCriteria.searchRequest && !this.viewData.filter.filterCriteria.searchRequest.actions) ? null : this.viewData.filter.filterCriteria : this.viewData.filter;
    const selectedColumns = this.useDefaultPresentation ? null : this.selectedColumnsData;

    this.openSaveSearch(filterData, selectedColumns, SaveOperationType.EditDetails);
  };

  deleteSavedSearch = (): any => {
    this.notificationService
      .confirmDelete({
        message: 'caseSearch.presentationColumns.savedSearchDelete'
      })
      .then(() => {
        this.caseSearchService.DeletePresentation(this.queryKey).subscribe(res => {
          if (res) {
            const stateName = this.hasTaskPlannerContext() ? 'taskPlannerSearchBuilder' : 'casesearch';
            this.taskPlannerService.isSavedSearchDeleted = true;
            this.stateService.go(stateName, {
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

  presentationExtendQuery = (query: any): any => {
    return {
      ...query,
      queryContextKey: this.queryContextKey
    };
  };

  ngDoCheck(): void {
    if (this.onChangeAction) {
      const change = this.differ.diff(this.selectedColumns);
      if (change) {
        this.triggerChangeAction();
      }
    }
  }

  initializePresentationData = () => {
    const searchPresentationData = this.searchPresentationService.getSearchPresentationData(this.activeTabSeq.toString());
    if (searchPresentationData) {
      this.selectedColumns = searchPresentationData.selectedColumns;
      this.availableColumnsStore = searchPresentationData.availableColumnsStore;
      this.availableColumnsForSearch = searchPresentationData.availableColumnsForSearch;
      this.useDefaultPresentation = searchPresentationData.useDefaultPresentation;
      this.copyPresentationQuery = searchPresentationData.copyPresentationQuery;
      this.dueDateFormData = searchPresentationData.dueDateFormData;
      this.availableColumns.next(this.sortKendoTreeviewDataSet(this.availableColumnsForSearch));
      this.viewData.filter = this.viewData.filter != null ? this.viewData.filter : {};
    }
  };

  persistPresentationData = () => {
    this.populateSelectedColumns();
    const presentationData = new SearchPresentationData();
    presentationData.selectedColumns = this.selectedColumns;
    presentationData.selectedColumnsData = this.useDefaultPresentation ? null : this.selectedColumnsData;
    presentationData.availableColumnsStore = this.availableColumnsStore;
    presentationData.availableColumnsForSearch = this.availableColumnsForSearch;
    presentationData.useDefaultPresentation = this.useDefaultPresentation;
    presentationData.copyPresentationQuery = this.copyPresentationQuery;
    presentationData.dueDateFormData = this.dueDateFormData;
    this.searchPresentationService.setSearchPresentationData(presentationData, this.activeTabSeq.toString());
  };

  checkDateColumns = (): void => {
    const validator = this.dueDateColumnsValidator
      .validate(this.viewData.isExternal, this.selectedColumns);
    this.hasDueDateColumn = validator.hasDueDateColumn;
    this.hasAllDateColumn = validator.hasAllDateColumn;
  };

  manageDueDateModal = (): void => {
    const initialState = {
      existingFormData: this.dueDateFormData ? this.dueDateFormData :
        this.caseSearchService.caseSearchData ? this.caseSearchService.caseSearchData.savedSearchData.dueDateFormData
          : null,
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
          this.viewData.filter = this.viewData.filter != null ? this.viewData.filter : {};
          this.viewData.filter.dueDateFilter = this.dueDateFilter;
          if (this.caseSearchService.caseSearchData != null) {
            this.caseSearchService.caseSearchData.savedSearchData.dueDateFormData = this.dueDateFormData;
          }
          this.dueDateModalRef.hide();
          this.isDueDatePoupOpen = false;
          if (!callbackParams.isModalClosed) {
            this.setPresentationAndSearch();
          }
        }
      );
    }
  };

  openDueDate = (): void => {
    this.keyBoardShortCutService.push();
    const queryKey = this.viewData.queryKey ? this.viewData.queryKey : this.stateParams.queryKey;
    if (this.viewData.filter == null && queryKey) {
      this.dueDateFormData = this.service.getDueDateSavedSearch(queryKey).subscribe((res: any) => {
        this.dueDateFormData = res.dueDateFormData;
        this.manageDueDateModal();
      });
    } else {
      if (!this.viewData.filter) {
        this.viewData.filter = { searchRequest: [] };
      }
      this.manageDueDateModal();
    }
  };

  setPresentationAndSearch = (): void => {
    this.persistPresentationData();
    this.stateService.go('search-results', {
      filter: this.viewData.filter,
      queryKey: this.viewData.queryKey,
      q: this.viewData.q,
      searchQueryKey: true,
      queryContext: this.queryContextKey,
      rowKey: null,
      selectedColumns: this.selectedColumnsData
    });
  };

  onkeyup(): void {
    if (!this.searchTerm) {
      this.availableColumns.next(this.sortKendoTreeviewDataSet(this.availableColumnsForSearch));
      this.expandkeys = [];
    } else {
      const searchedItem = this.search();
      _.each(searchedItem.filter(x => x.parentId !== null), (item) => {
        const checkForParent =
          _.first(this.availableColumnsStore.filter(x => x.id === item.parentId && x.parentId === null));
        if (checkForParent) {
          if (!searchedItem.find(x => x.id === checkForParent.id)) {
            searchedItem.splice(0, 0, checkForParent);
          }
        }
      });
      this.availableColumns.next(searchedItem);
      for (let i = 0; i < searchedItem.filter(x => x.isGroup).length; i++) {
        this.expandkeys.push(i.toString());
      }
    }
  }

  search(): Array<any> {
    return this.availableColumnsForSearch.reduce((acc, item) => {
      if (this.contains(item.displayName, this.searchTerm)) {
        acc.push(item);
      }

      return acc;
    }, []);
  }

  dataItemClicked = (dataItem) => {
    const exists = _.any(this.selectedColumnsMultipleSelelction, (item) => {
      return _.isEqual(item.id, dataItem.id);
    });
    if (!exists) {
      this.selectedColumnsMultipleSelelction.push(dataItem);
    } else {
      this.selectedColumnsMultipleSelelction = _.without(this.selectedColumnsMultipleSelelction,
        _.findWhere(this.selectedColumnsMultipleSelelction,
          { id: dataItem.id }));
    }
  };

  buildGridOptions(): IpxGridOptions {
    return {
      selectable: {
        mode: 'single'
      },
      draggable: true,
      gridMessages: {
        noResultsFound: 'dragDropNoRecordFound'
      },
      customRowClass: (context) => {
        const exists = _.any(this.selectedColumnsMultipleSelelction, (item) => {
          return _.isEqual(item.id, context.dataItem.id);
        });
        const returnValue = exists ? 'k-state-selected selected' : '';

        return returnValue;
      },
      read$: () => {
        if (this.isAvailableColumnEdit) {
          this.service.getAvailableColumns(this.queryContextKey).subscribe(available => {
            if (this.upatedColumnKey) {
              const updated: any = _.first(available.filter(a => a.columnKey === this.upatedColumnKey));
              updated.saved = true;
            }
            this.filterAvailableColumns(available, this.selectedColumns);
            if (this.searchTerm) {
              this.onkeyup();
            }
          });

        } else {
          if (this.getSelectedColumnsOnly) {
            return this.service.getSelectedColumns(this.queryKey, this.queryContextKey)
              .pipe(
                map((selected) => {
                  this.initializeOrder(selected.length);
                  this.searchTerm = null;
                  this.expandkeys = [];
                  this.filterAvailableColumns(this.availableColumnsStore, selected);
                  this.useDefaultPresentation = _.any(selected, (item) => {
                    this.manageGroupingAccess(this.selectedColumns);

                    return item.isDefault === true;
                  });
                  if (this.isDefaultOrRevertPresentation) {
                    this.useDefaultPresentation = true;
                  }

                  if (this.useDefaultPresentation) {
                    this.copyPresentationQuery = null;
                  }
                  this.isDefaultOrRevertPresentation = false;
                  this.checkDateColumns();

                  return selected;
                })
              );
          }
          if (!this.dragControl || this.refreshPresentation) {
            return _.any(this.selectedColumns) ? of(this.selectedColumns).pipe(delay(100)).pipe(map(selected => {
              this.initializeOrder(selected.length);
              this.checkDateColumns();

              return selected;
            })) : forkJoin(
              this.service.getAvailableColumns(this.queryContextKey),
              this.service.getSelectedColumns(this.refreshPresentation ? null : this.queryKey, this.queryContextKey)
            ).pipe(
              map(([available, selected]) => {
                let selectedTemp = selected;
                if (this.stateParams.selectedColumns && !this.refreshPresentation) {
                  selectedTemp = this.stateParams.selectedColumns.map(pc => {
                    const found = available.find((c) => {
                      return (c && pc && c.columnKey === pc.columnKey);
                    });

                    if (found) {
                      found.hidden = pc.displaySequence == null;
                      found.freezeColumn = pc.isFreezeColumnIndex != null;
                      found.sortDirection = pc.sortDirection;
                      found.sortOrder = pc.sortOrder;
                      found.groupBySortDirection = pc.groupBySortDirection;
                      found.groupBySortOrder = pc.groupBySortOrder;
                      found.freezeColumn = pc.isFreezeColumnIndex || false;
                      found.displaySequence = pc.displaySequence;

                      return found;
                    }

                  }).filter((pc) => (pc && pc.columnKey != null));
                }
                this.useDefaultPresentation = _.any(selected, (item) => {
                  return item.isDefault === true;
                });
                if (!this.isTaskPlannerPresentation) {
                  let frozen = false;
                  for (let i = selectedTemp.length - 1; i >= 0; i--) {
                    if (selectedTemp[i].freezeColumn || frozen) {
                      if (!selectedTemp[i].hidden) {
                        selectedTemp[i].freezeColumn = true;
                      }
                      frozen = true;
                    }
                  }
                }

                this.initializeOrder(selectedTemp.length);
                this.filterAvailableColumns(available, selectedTemp);
                this.checkDateColumns();
                this.manageGroupingAccess(selectedTemp);

                return selectedTemp;
              }));
          }
        }

        return of(this.selectedColumns).pipe(map(selected => {
          this.manageGroupingAccess(this.selectedColumns);
          this.checkDateColumns();

          return selected;
        }));

      },
      columns: this.buildSelectedColumns()
    };
  }

  buildSelectedColumns(): any {
    const columns = [{
      field: 'displayName', title: 'caseSearch.presentationColumns.selectedColumns.displayName', width: 175, template: true
    }, {
      field: 'sortOrder', title: 'caseSearch.presentationColumns.selectedColumns.sortOrder', width: 75, template: true
    }, {
      field: 'sortDirection', title: 'caseSearch.presentationColumns.selectedColumns.sortDirection', width: 100, template: true
    }, {
      field: 'hidden', title: 'caseSearch.presentationColumns.selectedColumns.hidden', width: 75, template: true
    }, {
      field: 'freezeColumn', title: 'caseSearch.presentationColumns.selectedColumns.freezeColumn', width: 75, template: true
    }, {
      field: 'groupBySortOrder', title: 'caseSearch.presentationColumns.selectedColumns.groupBySortOrder', width: 75, template: true
    }, {
      field: 'groupBySortDirection', title: 'caseSearch.presentationColumns.selectedColumns.groupBySortDirection', width: 100, template: true
    }];
    if (+this.queryContextKey === queryContextKeyEnum.taskPlannerSearch) {
      this.isTaskPlannerPresentation = true;
      columns.splice(4, 1);
    }

    return columns;
  }

  executeSearch = (): void => {
    if (+this.queryContextKey === queryContextKeyEnum.taskPlannerSearch) {
      this.persistPresentationData();
      this.stateService.go('taskPlanner',
        {
          filterCriteria: this.stateParams && this.stateParams.filter ? this.stateParams.filter.filterCriteria : null,
          formData: this.stateParams && this.stateParams.filter ? this.stateParams.filter.formData : null,
          activeTabSeq: this.activeTabSeq,
          searchBuilder: true,
          selectedColumns: this.selectedColumnsData,
          queryKey: this.viewData.queryKey,
          searchName: this.queryName,
          isSelectedColumnChange: this.isSelectedColumnAttributeChanged
        });
    } else {
      this.checkDateColumns();
      if (this.hasDueDateColumn || this.hasAllDateColumn) {
        this.openDueDate();
      } else {
        this.setPresentationAndSearch();
      }
    }

  };

  setOnChangeAction = (payload: any, then: (val: any) => any): void => {
    this.onChangeAction = () => {
      const data = this.hostSearchOutput();

      if (payload) {
        then({ ...payload, ...data });
      }
    };
  };

  setOnHostNavigation = (payload: any, then: (val: any) => any): void => {
    this.onNavigationAction = (e: any) => {
      if (e) {
        this.persistPresentationData();
        const data = this.hostSearchOutput();
        if (payload) {
          then({ ...payload, ...data });
        }
      }
    };
  };

  removeOnChangeAction = () => {
    this.onChangeAction = null;
    this.isShowingHeader = true;
    this.cdRef.markForCheck();
  };

  triggerChangeAction = () => {
    if (this.onChangeAction) {
      setTimeout(() => {
        this.onChangeAction();
      }, 400);
    }
  };

  populateSelectedColumns = (): void => {
    let displaySequence = 1;
    const freezeColumnIndex = this.selectedColumns.map(c => c.freezeColumn).lastIndexOf(true);
    this.selectedColumnsData = _.map(this.selectedColumns, (sc) => {
      return {
        columnKey: sc.columnKey,
        sortDirection: sc.sortDirection,
        sortOrder: sc.sortOrder,
        groupBySortDirection: sc.groupBySortDirection,
        groupBySortOrder: sc.groupBySortOrder,
        displaySequence: sc.hidden ? null : displaySequence++
      };
    });
    if (freezeColumnIndex > -1) {
      this.selectedColumnsData[freezeColumnIndex].isFreezeColumnIndex = true;
    }
  };

  filterAvailableColumns(available: Array<PresentationColumnView>, selected: Array<PresentationColumnView>): void {
    this.availableColumnsStore = available;
    const selectedColumnsFilter = selected.map(item => { return item.id; });
    let filtered = _.filter(this.availableColumnsStore, (avl) => {
      return !_.contains(selectedColumnsFilter, avl.id);
    });
    const groupTodeleteWhenNoChild = _.filter(filtered, (f) => {
      return f.isGroup && !_.any(filtered, (fi) => fi.parentId === f.id);
    });
    filtered = _.filter(filtered, (av) => {
      return !_.contains(groupTodeleteWhenNoChild, av);
    });
    this.availableColumns.next(filtered);
    this.selectedColumns = selected;
    this.availableColumnsForSearch = [...filtered];
  }

  onDrop(e, dropZone): void {
    e.preventDefault();
    if (_.isEqual(this.dragControl, 'kendoTreeView') && _.isEqual(dropZone, 'kendoTreeView')) {
      return;
    }
    this.getSelectedColumnsOnly = false;
    const data = e.dataTransfer.getData('text');
    if (data) {
      this.droppedItem = JSON.parse(data);
    }

    if (dropZone === 'kendoGrid') {
      if (this.dragControl === 'kendoGrid') {
        this.dropItemFromKendoGridToKendoGrid(this.droppedItem);
      } else {
        this.availableColumnsMultipleSelelction.length === 0 ?
          this.dropItemFromTreeViewToGrid(this.droppedItem) :
          this.handleMultiplerecordForTreeview();
        this.availableColumns.next(this.reduce(this.availableColumns.getValue()));
      }
      this.useDefaultPresentation = false;
    } else if (dropZone === 'kendoTreeView') {
      this.selectedColumnsMultipleSelelction.length === 0 ?
        this.dropItemFromGridToTreeView(this.droppedItem) :
        this.makeMultiplerecordForKendoGrid(this.selectedColumnsMultipleSelelction);
      this.availableColumns.next(this.reduce(this.sortKendoTreeviewDataSet(this.availableColumns.getValue())));
      this.availableColumnsForSearch = _.union(this.availableColumnsForSearch, this.availableColumns.getValue());
      if (this.searchTerm) {
        this.onkeyup();
      }
    }
    if (data) {
      if (dropZone !== 'kendoTreeView') {
        this.updateFreezeColumns(this.droppedItem);
      }
    }
    this.gridOptions._search();
    this.setDragableAttributeForKendoGrid(this.selectedColumns);
    this.initializeOrder(this.selectedColumns.length);
    this.isSelectedColumnAttributeChanged = true;
  }

  makeMultiplerecordForKendoGrid(itemList: any): void {
    if (!_.any(itemList, (itemExist: any) => { return _.isEqual(itemExist.id, this.droppedItem.id); })) {
      itemList.push(this.droppedItem);
    }
    _.each(itemList, (item) => {
      this.dropItemFromGridToTreeView(item);
    });
    this.selectedColumnsMultipleSelelction = [];
  }

  handleMultiplerecordForTreeview(): void {
    if (!_.any(this.availableColumnsMultipleSelelction, (itemExist: any) => { return _.isEqual(itemExist.id, this.droppedItem.id); })) {
      this.availableColumnsMultipleSelelction.push(this.droppedItem.id);
    }
    const filteredItems = _.filter(this.availableColumnsForSearch, (av) => {
      return _.contains(this.availableColumnsMultipleSelelction, av.id);
    });
    const isColumnOnly = _.filter(filteredItems, (item) => {
      return item.isGroup === false && item.parentId !== null && _.contains(this.availableColumnsMultipleSelelction, item.parentId);
    });
    const differenceItem = _.difference(filteredItems, isColumnOnly);
    _.each(differenceItem, (item) => {
      this.dropItemFromTreeViewToGrid(item);
      this.dropIndex++;
    });
    if (differenceItem.filter(x => x.isGroup === true).length >= 2) {
      this.isTreeCollapsed([], true);
    }
    this.availableColumnsMultipleSelelction = [];
  }

  maintainSearchFilter(droppedItem: any): void {
    this.availableColumnsForSearch = _.without(this.availableColumnsForSearch, _.findWhere(this.availableColumnsForSearch, { id: droppedItem.id }));
    const checkForChild = _.filter(this.availableColumnsStore, (item) => {
      return _.isEqual(item.parentId, droppedItem.id);
    });
    if (checkForChild === null || checkForChild.length === 0) {
      if (droppedItem.parentId !== null) {
        const isOnlyParentAvailable = _.filter(this.availableColumnsForSearch, (item) => {
          return _.isEqual(item.parentId, droppedItem.parentId);
        });
        if (isOnlyParentAvailable.length === 0) {
          this.availableColumnsForSearch = _.filter(this.availableColumnsForSearch, (item) => {
            return item !== this.availableColumnsForSearch.filter(x => x.id === droppedItem.parentId)[0];
          });
        }
      }
    } else {
      this.availableColumnsForSearch = this.availableColumnsForSearch.filter((el) => (checkForChild.findIndex((elem) => (elem.id === el.id)) === -1));
    }
  }

  dropItemFromTreeViewToGrid(droppedItem: any): void {
    let currentItems = this.availableColumns.getValue();
    currentItems = _.without(currentItems, _.findWhere(currentItems, { id: droppedItem.id }));
    const checkForChild = _.filter(this.availableColumnsStore, (item) => {
      return _.isEqual(item.parentId, droppedItem.id);
    });

    if (checkForChild === null || checkForChild.length === 0) {
      if (droppedItem.parentId !== null) {
        const isOnlyParentAvailable = _.filter(currentItems, (item) => {
          return _.isEqual(item.parentId, droppedItem.parentId);
        });
        if (isOnlyParentAvailable.length === 0) {
          currentItems = _.filter(currentItems, (item) => {
            return item !== currentItems.filter(x => x.id === droppedItem.parentId)[0];
          });
        }
      }
      if (!_.any(this.selectedColumns, (itemExist) => { return _.isEqual(itemExist.id, droppedItem.id); })) {
        this.selectedColumns.splice(this.dropIndex, 0, droppedItem);
      }
    } else {
      currentItems = currentItems.filter((el) => (checkForChild.findIndex((elem) => (elem.id === el.id)) === -1));
      const allChildItem = _.filter(checkForChild, (obj) => {
        return !this.selectedColumns.some((obj2) => {
          return obj.id === obj2.id;
        });
      });
      this.selectedColumns.splice(this.dropIndex, 0, ...allChildItem);
    }
    this.maintainSearchFilter(droppedItem);
    this.availableColumns.next(currentItems);
  }

  dropItemFromKendoGridToKendoGrid(droppedItem: any): void {
    this.selectedColumns = _.without(this.selectedColumns, _.findWhere(this.selectedColumns, { id: droppedItem.id }));
    this.selectedColumns.splice(this.dropIndex, 0, droppedItem);
    this.selectedColumnsMultipleSelelction = [];
    this.selectedColumnsMultipleSelelction.push(droppedItem);
  }

  dropItemFromGridToTreeView(droppedItem: any): void {
    if (!droppedItem.isMandatory) {
      droppedItem.freezeColumn = false;
      droppedItem.sortOrder = null;
      droppedItem.groupBySortOrder = null;
      droppedItem.hidden = false;
      droppedItem.sortDirection = null;
      droppedItem.groupBySortDirection = null;
      this.selectedColumns = _.without(this.selectedColumns, _.findWhere(this.selectedColumns, { id: droppedItem.id }));
      const currentItems = this.availableColumns.getValue();
      if (droppedItem.parentId === null) {
        currentItems.splice(this.dropIndex, 0, droppedItem);
      } else {
        const checkForParent = _.filter(this.availableColumnsStore, (item) => {
          return (_.isEqual(item.id, droppedItem.parentId) && item.parentId === null);
        });
        if (checkForParent != null || checkForParent !== undefined) {
          const ifParentAvialabe = _.find(currentItems, (item) => {
            return _.isEqual(item.id, checkForParent[0].id);
          });
          if (!ifParentAvialabe) {
            currentItems.splice(this.dropIndex, 0, checkForParent[0]);
            if (!_.any(currentItems, (itemExist) => { return _.isEqual(itemExist.id, droppedItem.id); })) {
              currentItems.splice(this.dropIndex, 0, droppedItem);
            }
          } else {
            if (!_.any(currentItems, (itemExist) => { return _.isEqual(itemExist.id, droppedItem.id); })) {
              currentItems.splice(this.dropIndex, 0, droppedItem);
            }
          }
        }
      }
      this.resetOrder(null, 'sortOrder');
      this.resetOrder(null, 'groupBySortOrder');
      this.availableColumns.next(currentItems);
    }
  }

  initializeOrder(length: Number): void {
    this.sortOrder = [];

    for (let i = 1; i <= length; i++) {
      this.sortOrder.push(i);
    }
  }

  onOrderClick(dataItem: any, sortDirection: String, directionType: string, orderType: string): void {
    if (this.anyColumnsFreezed()) {
      return;
    }
    dataItem[directionType] = dataItem[orderType] !== null && dataItem[orderType] !== '' ? sortDirection : '';
    this.useDefaultPresentation = false;
    this.isSelectedColumnAttributeChanged = true;
  }

  onOrderChange(e: any, dataItem: any, directionType: string, orderType: string): void {
    const index = this.selectedColumns.findIndex(i => i.id === dataItem.id);
    if (!dataItem[orderType]) {
      this.selectedColumns[index][orderType] = null;
      this.selectedColumns[index][directionType] = null;
      this.selectedColumns[index].hidden = false;
      this.selectedColumns[index].isGroupBySortOrderDisabled = false;
    } else {
      this.selectedColumns[index][directionType] = dataItem[directionType] ? dataItem[directionType] : 'A';
    }
    this.resetSortOrder(e, dataItem, orderType);
    this.triggerChangeAction();
    this.isSelectedColumnAttributeChanged = true;
  }

  resetSortOrder(e: any, dataItem: any, orderType: string): void {
    const sortColumnsCount = _.filter(this.selectedColumns, (item: any) => {
      return item[orderType] !== null && item[orderType] !== '';
    }).length;
    if (dataItem[orderType] > sortColumnsCount) {
      dataItem[orderType] = sortColumnsCount;
      if (e.taret) {
        e.target.value = sortColumnsCount;
      }
    }
    this.resetOrder(dataItem, orderType);
  }

  resetOrder(dataItem: any, orderType: string): void {
    const columnsToOrder = _.filter(this.selectedColumns, (item: any) => {
      return item[orderType] !== null && item[orderType] !== '' && (dataItem === null || item.id !== dataItem.id);
    }).sort((c1, c2) => (c1[orderType] > c2[orderType]) ? 1 : -1);

    let i = 0;
    _.each(columnsToOrder, (col) => {
      i++;
      if (dataItem !== null && i === dataItem[orderType]) {
        i++;
      }
      _.each(this.selectedColumns, (selectedColumn) => {
        if (selectedColumn.id === col.id) {
          selectedColumn[orderType] = i;
        }
      });
    });
    this.useDefaultPresentation = false;
    this.cdRef.detectChanges();
  }

  onHiddenClick(dataItem: any): void {
    const index = this.selectedColumns.findIndex(i => i.id === dataItem.id);
    this.manageGroupByColumn(this.selectedColumns[index].hidden, index);
    if (!this.isTaskPlannerPresentation) {
      this.manageFreezeColumn(index);
    }
    this.triggerChangeAction();
    this.isSelectedColumnAttributeChanged = true;
  }

  manageGroupByColumn(isHidden: Boolean, index: number): void {
    if (isHidden) {
      this.selectedColumns[index].isGroupBySortOrderDisabled = true;
      this.selectedColumns[index].groupBySortOrder = null;
      this.selectedColumns[index].groupBySortDirection = null;
    } else {
      this.selectedColumns[index].isGroupBySortOrderDisabled = false;
    }
  }

  setGroupingAllowed(): void {
    const enabledContextIds: Array<SearchContextEnum> = [
      SearchContextEnum.CaseSearchExternal,
      SearchContextEnum.CaseSearch,
      SearchContextEnum.NameSearch,
      SearchContextEnum.NameSearchExternal,
      SearchContextEnum.OpportunitySearch,
      SearchContextEnum.CampaignSearch,
      SearchContextEnum.MarketingEventSearch,
      SearchContextEnum.LeadSearch,
      SearchContextEnum.WIPOverviewSearch,
      SearchContextEnum.PriorAreSearch,
      SearchContextEnum.TaskPlannerSearch
    ];
    if (_.contains(enabledContextIds, +this.queryContextKey, 0)) {
      this.isGroupingAllowed = true;
    }
  }

  manageGroupingAccess(columns: Array<PresentationColumnView>): void {
    if (!this.isGroupingAllowed) {
      columns.forEach(x => (x.isGroupBySortOrderDisabled = true) && (x.isFreezeColumnDisabled = true));
    }
  }

  manageFreezeColumn(index: number): void {
    if (this.selectedColumns[index].sortOrder && this.selectedColumns[index].hidden) {
      this.selectedColumns[index].freezeColumn = false;
      this.selectedColumns[index].isFreezeColumnDisabled = true;
    } else {
      this.selectedColumns[index].isFreezeColumnDisabled = false;
    }
    this.manageGroupingAccess(this.selectedColumns);
    this.useDefaultPresentation = false;
  }

  editSearchCriteria(): void {
    this.persistPresentationData();
    if (+this.queryContextKey === queryContextKeyEnum.taskPlannerSearch) {
      this.stateService.go('taskPlannerSearchBuilder', {
        queryKey: this.viewData.queryKey,
        canEdit: this.viewData.queryKey !== null,
        filterCriteria: this.stateParams && this.stateParams.filter ? this.stateParams.filter.filterCriteria : null,
        formData: this.stateParams && this.stateParams.filter ? this.stateParams.filter.formData : null,
        selectedColumns: this.selectedColumnsData,
        activeTabSeq: this.activeTabSeq
      });
    } else {
      this.stateService.go('casesearch', {
        queryKey: this.viewData.queryKey,
        canEdit: this.viewData.queryKey !== null,
        returnFromCaseSearchResults: true
      });
    }
  }

  anyColumnsFreezed(): boolean {
    return _.any(this.selectedColumns, (sc: any) => {
      return sc.freezeColumn === true;
    });
  }

  onDefaultPresentationChanged(): void {
    this.isSelectedColumnAttributeChanged = true;
    if (!this.useDefaultPresentation) {
      return;
    }
    this.queryKey = null;
    this.copyPresentationQuery = null;
    this.getSelectedColumnsOnly = true;
    this.availableColumnsMultipleSelelction = [];
    this.selectedColumnsMultipleSelelction = [];
    this.expandkeys = [];
    this.gridOptions._search();
    this.cdRef.detectChanges();
  }

  onSavedQueriesChanged(): void {
    if (!this.copyPresentationQuery) {

      return;
    }
    this.queryKey = +this.copyPresentationQuery.key;
    if (this.queryKey) {
      this.useDefaultPresentation = false;
      this.getSelectedColumnsOnly = true;
      this.availableColumnsMultipleSelelction = [];
      this.selectedColumnsMultipleSelelction = [];
      this.isDefaultOrRevertPresentation = false;
      this.gridOptions._search();
      this.isSelectedColumnAttributeChanged = true;
    }
  }

  updateFreezeColumns(dataItem: any): void {
    const freezedIndex = this.selectedColumns.findIndex(x => x.id === dataItem.id);
    if (freezedIndex !== -1) {
      if (dataItem.freezeColumn === false) {
        for (let i = freezedIndex; i < this.selectedColumns.length; i++) {
          this.selectedColumns[i].freezeColumn = false;
        }
      } else {
        for (let i = 0; i <= freezedIndex; i++) {
          this.selectedColumns[i].freezeColumn = this.selectedColumns[i].hidden ? false : true;
        }
      }
    } else {
      for (let i = this.dropIndex; i < this.selectedColumns.length; i++) {
        this.selectedColumns[i].freezeColumn = false;
      }
    }
    this.useDefaultPresentation = false;
    this.triggerChangeAction();
    this.isSelectedColumnAttributeChanged = true;
  }

  saveSearch = (): any => {
    this.populateSelectedColumns();
    const filterData = this.hasTaskPlannerContext() ? (this.viewData.filter.filterCriteria.searchRequest && !this.viewData.filter.filterCriteria.searchRequest.actions) ? null : this.viewData.filter.filterCriteria : this.viewData.filter;
    const selectedColumns = this.useDefaultPresentation ? null : this.selectedColumnsData;

    if (this.viewData.queryKey) {
      this.executeSaveSearch(filterData, selectedColumns);
    } else {
      this.openSaveSearch(filterData, selectedColumns, SaveOperationType.Add);
    }
  };

  openSaveSearch = (filterData: any, selectedColumns: Array<SelectedColumn>, type: SaveOperationType): any => {
    const initialState = {
      queryKey: (type === SaveOperationType.EditDetails || type === SaveOperationType.SaveAs ? this.queryKey : null),
      type,
      updatePresentation: true,
      selectedColumns,
      filter: filterData,
      queryContextKey: this.queryContextKey,
      canMaintainPublicSearch: this.canMaintainPublicSearch
    };
    this.modalService.openModal(SavedSearchComponent, {
      animated: false,
      backdrop: 'static',
      class: 'modal-lg',
      initialState
    });
  };
  private readonly hostSearchOutput = (): any => {
    this.populateSelectedColumns();
    // TODO Replace with new state

    return {
      payload: {
        action: 'search-results', // TODO create enum for post message actions
        // tslint:disable-next-line: strict-boolean-expressions
        filter: this.viewData.filter || null,
        // tslint:disable-next-line: strict-boolean-expressions
        queryKey: this.viewData.queryKey || null,
        searchQueryKey: true,
        rowKey: null,
        selectedColumns: this.selectedColumnsData,
        copyComplete: this.getSelectedColumnsOnly && !this.useDefaultPresentation
      }
    };
  };

  executeSaveSearch = (filterData: any, selectedColumns: Array<SelectedColumn>): any => {
    const saveSearchEntity: SaveSearchEntity = {
      searchFilter: filterData,
      updatePresentation: true,
      queryContext: this.queryContextKey,
      selectedColumns
    };

    this.savedSearchService.saveSearch(saveSearchEntity, SaveOperationType.Update, this.viewData.queryKey, SearchTypeConfigProvider.savedConfig).subscribe(res => {
      if (res.success) {
        this.notificationService.success('saveMessage');
        this.copyPresentationQuery = null;
        this.isSelectedColumnAttributeChanged = false;
      }
    });
  };

  openSearchColumns = (): any => {
    this.stateService.go('searchcolumns', {
      filter: this.viewData.filter,
      queryKey: this.viewData.queryKey,
      q: this.viewData.q,
      searchQueryKey: true,
      queryContextKey: this.queryContextKey,
      rowKey: null,
      selectedColumns: this.selectedColumnsData
    });
  };

  hasTaskPlannerContext = (): boolean => {
    return +this.queryContextKey === queryContextKeyEnum.taskPlannerSearch;
  };

}