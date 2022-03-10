import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { StateService } from '@uirouter/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BehaviorSubject, of, Subscription } from 'rxjs';
import { map, takeUntil } from 'rxjs/operators';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType, GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import { DataValidationSearchModel, SanityCheckConfigurationService } from './sanity-check-configuration.service';
import { SanitySearchBaseClass } from './sanity-search-base-class';

@Component({
  selector: 'app-sanity-check',
  templateUrl: './sanity-check-configuration.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  animations: [
    slideInOutVisible
  ],
  providers: [IpxDestroy]
})
export class SanityCheckConfigurationComponent implements OnInit, AfterViewInit {
  @Input() stateParams: any;
  @Input() viewInitialiser: any;

  showSearchBar = true;
  matchType: 'case' | 'name';
  formData: any;
  gridOptionsCase: IpxGridOptions;
  gridOptionsName: IpxGridOptions;
  @ViewChild('searchByCase') searchByCaseComp: SanitySearchBaseClass;
  @ViewChild('searchByName') searchByNameComp: SanitySearchBaseClass;
  @ViewChild('ipxKendoGridRefCase', { static: false }) gridCase: IpxKendoGridComponent;
  @ViewChild('ipxKendoGridRefName', { static: false }) gridName: IpxKendoGridComponent;
  selectionCountSubject = new BehaviorSubject<number>(0);
  anySelected$ = this.selectionCountSubject.asObservable().pipe(map((n) => n > 0));
  singleSelected$ = this.selectionCountSubject.asObservable().pipe(map((n) => n === 1));
  canSelectCase: boolean;
  canSelectName: boolean;
  gridChangeSubscription: Subscription;
  get searchByComp(): SanitySearchBaseClass {
    if (this.matchType === 'name') {

      return this.searchByNameComp;
    }

    return this.searchByCaseComp;
  }

  get grid(): IpxKendoGridComponent {
    return this.matchType === 'name' ? this.gridName : this.gridCase;
  }

  get gridOptions(): IpxGridOptions {
    if (this.matchType === 'name') {
      return this.gridOptionsName;
    }

    return this.gridOptionsCase;
  }

  private readonly canCreate = (selectedMatchType: string): boolean => {
    if (selectedMatchType === 'name') {
      return this.viewInitialiser.canCreateForName;
    }

    return this.viewInitialiser.canCreateForCase;
  };

  private readonly canUpdate = (type: 'case' | 'name'): boolean => {
    if (type === 'name') {
      return this.viewInitialiser.canUpdateForName;
    }

    return this.viewInitialiser.canUpdateForCase;
  };

  private readonly canDelete = (type: 'case' | 'name'): boolean => {
    return type === 'name' ? this.viewInitialiser.canDeleteForName : this.viewInitialiser.canDeleteForCase;
  };

  constructor(public service: SanityCheckConfigurationService, private readonly stateService: StateService, private readonly destroy$: IpxDestroy,
    private readonly notificationService: NotificationService, private readonly shortcutService: IpxShortcutsService, private readonly cdf: ChangeDetectorRef) {
  }

  ngOnInit(): void {
    this.matchType = this.stateParams.matchType;
    this.canSelectCase = this.viewInitialiser.canCreateForCase || this.viewInitialiser.canUpdateForCase || this.viewInitialiser.canDeleteForCase;
    this.canSelectName = this.viewInitialiser.canCreateForName || this.viewInitialiser.canUpdateForName || this.viewInitialiser.canDeleteForName;

    this.gridOptionsCase = this.buildGridOptions('case');
    this.gridOptionsName = this.buildGridOptions('name');
    this.formData = { inUse: true };

    this.handleShortcuts();
  }

  handleShortcuts(): void {
    const shortcutCallbacksMap = new Map([[RegisterableShortcuts.ADD, (): void => { this.grid.onAdd(); }]]);
    this.shortcutService.observeMultiple$([RegisterableShortcuts.ADD])
      .pipe(takeUntil(this.destroy$))
      .subscribe((key: RegisterableShortcuts) => {
        if (!!key && shortcutCallbacksMap.has(key)) {
          shortcutCallbacksMap.get(key)();
        }
      });
  }

  ngAfterViewInit(): void {
    this.subscribeGridChange();
    if (!!this.stateParams.isLevelUp) {
      switch (this.matchType) {
        case 'case':
          const caseCharacteristicsSearchCriteria = this.service.getSearchData('caseCharacteristics');
          const otherSearchCriteria = this.service.getSearchData('otherData');
          this.searchByComp.resetFormData(!!caseCharacteristicsSearchCriteria ? { ...caseCharacteristicsSearchCriteria } : null);
          this.formData = !!otherSearchCriteria ? { ...otherSearchCriteria } : { inUse: true };
          if (!!caseCharacteristicsSearchCriteria || !!otherSearchCriteria) {
            this.search();

            return;
          }
          break;
        case 'name':
          const nameCharacteristicsSearchCriteria = this.service.getSearchData('nameCharacteristics');
          const otherNameSearchCriteria = this.service.getSearchData('otherNameData');
          this.searchByComp.resetFormData(!!nameCharacteristicsSearchCriteria ? { ...nameCharacteristicsSearchCriteria } : null);
          this.formData = !!otherNameSearchCriteria ? { ...otherNameSearchCriteria } : { inUse: true };
          if (!!nameCharacteristicsSearchCriteria || !!otherNameSearchCriteria) {
            this.search();

            return;
          }
          break;
        default: break;
      }
    }
  }

  resetFormData(): void {
    this.searchByComp.resetFormData();

    this.grid.clear();
    this.formData = { inUse: true };
  }
  search(): void {
    this.gridOptions._search();
  }

  private readonly buildGridOptions = (type: 'case' | 'name'): IpxGridOptions => {
    const actions = this.getActions(type);
    let options: IpxGridOptions = {
      manualOperations: true,
      selectable: {
        mode: 'single'
      },
      sortable: false,
      showGridMessagesUsingInlineAlert: false,
      autobind: false,
      persistSelection: false,
      enableGridAdd: this.canCreate(type),
      canAdd: this.canCreate(type),
      navigable: false,
      pageable: false,
      gridMessages: {
        noResultsFound: 'grid.messages.noItems',
        performSearch: ''
      },
      read$: (queryParams) => {
        switch (type) {
          case 'case': return this.caseRuleSearch(queryParams);
          case 'name': return this.nameRuleSearch(queryParams);
          default: break;
        }

        return of({});
      },
      columns: this.getColumns(type),
      gridAddDelegate: () => {
        this.stateService.go('sanityCheckMaintenanceInsert', {
          matchType: type
        });
      }
    };

    if (this.canDelete(type) || this.canUpdate(type)) {
      options = {
        ...options, ...{
          selectable: {
            mode: 'multiple'
          },
          bulkActions: actions,
          selectedRecords: { rows: { rowKeyField: 'id', selectedKeys: [] } }
        }
      };
    }

    return options;
  };

  private readonly caseRuleSearch = (queryParams: any): any => {
    const data = { ...this.searchByComp.formData, ...this.formData };
    const searchData = this.getDataToSearchCaseRule(data);

    this.service.setSearchData('caseCharacteristics', { ...this.searchByComp.formData });
    this.service.setSearchData('otherData', { ...this.formData });

    return this.service.search$(this.matchType, searchData, queryParams);
  };

  private readonly nameRuleSearch = (queryParams: any): any => {
    const data = { ...this.searchByComp.formData, ...this.formData };
    const searchData = this.getDataToSearchNameRule(data);

    this.service.setSearchData('nameCharacteristics', { ...this.searchByComp.formData });
    this.service.setSearchData('otherNameData', { ...this.formData });

    return this.service.search$(this.matchType, searchData, queryParams);
  };

  private readonly getColumns = (type: 'case' | 'name'): Array<GridColumnDefinition> => {
    switch (type) {
      case 'case': return this.getCaseRuleColumns();
      case 'name': return this.getNameRuleColumns();

      default: break;
    }

    return null;
  };

  private readonly getNameRuleColumns = (): Array<GridColumnDefinition> => {
    const columns = [{
      title: 'sanityCheck.configurations.grid.ruleDescription',
      field: 'ruleDescription',
      template: true,
      sortable: true,
      width: 180
    }, {
      title: 'sanityCheck.configurations.grid.nameGroup',
      field: 'nameGroup',
      template: false,
      sortable: true,
      width: 90
    }, {
      title: 'sanityCheck.configurations.grid.name',
      field: 'name',
      template: false,
      sortable: true,
      width: 90
    }, {
      title: 'sanityCheck.configurations.country',
      field: 'jurisdiction',
      template: false,
      sortable: true,
      width: 90
    }, {
      title: 'sanityCheck.configurations.grid.category',
      field: 'category',
      template: false,
      sortable: true,
      width: 90
    }, {
      title: 'sanityCheck.configurations.grid.organization',
      field: 'organization',
      defaultColumnTemplate: DefaultColumnTemplateType.selection,
      disabled: true,
      sortable: false,
      width: 60
    }, {
      title: 'sanityCheck.configurations.grid.individual',
      field: 'individual',
      defaultColumnTemplate: DefaultColumnTemplateType.selection,
      disabled: true,
      sortable: false,
      width: 60
    }, {
      title: 'sanityCheck.configurations.grid.clientOnly',
      field: 'client',
      defaultColumnTemplate: DefaultColumnTemplateType.selection,
      disabled: true,
      sortable: false,
      width: 60
    }, {
      title: 'sanityCheck.configurations.grid.staff',
      field: 'staff',
      defaultColumnTemplate: DefaultColumnTemplateType.selection,
      disabled: true,
      sortable: false,
      width: 60
    }, {
      title: 'sanityCheck.configurations.grid.supplierOnly',
      field: 'supplier',
      defaultColumnTemplate: DefaultColumnTemplateType.selection,
      disabled: true,
      sortable: false,
      width: 60
    }, {
      title: 'sanityCheck.configurations.grid.inUse',
      field: 'inUse',
      defaultColumnTemplate: DefaultColumnTemplateType.selection,
      disabled: true,
      sortable: false,
      width: 60
    }, {
      title: 'sanityCheck.configurations.grid.deferred',
      field: 'deferred',
      defaultColumnTemplate: DefaultColumnTemplateType.selection,
      disabled: true,
      sortable: false,
      width: 60
    }, {
      title: 'sanityCheck.configurations.grid.informational',
      field: 'informational',
      defaultColumnTemplate: DefaultColumnTemplateType.selection,
      disabled: true,
      sortable: false,
      width: 60
    }];

    return columns;
  };

  private readonly getCaseRuleColumns = (): Array<GridColumnDefinition> => {
    const columns = [
      {
        title: 'sanityCheck.configurations.grid.ruleDescription',
        field: 'ruleDescription',
        template: true,
        sortable: true,
        width: 180
      },
      {
        title: 'sanityCheck.configurations.grid.caseOffice',
        field: 'caseOffice',
        template: true,
        sortable: true,
        width: 90
      },
      {
        title: 'sanityCheck.configurations.grid.caseType',
        field: 'caseType',
        template: true,
        sortable: true,
        width: 120
      },
      {
        title: 'sanityCheck.configurations.grid.jurisdiction',
        field: 'jurisdiction',
        template: true,
        sortable: true,
        width: 120
      },
      {
        title: 'sanityCheck.configurations.grid.propertyType',
        field: 'propertyType',
        template: true,
        sortable: true,
        width: 120
      },
      {
        title: 'sanityCheck.configurations.grid.caseCategory',
        field: 'caseCategory',
        template: true,
        sortable: false,
        width: 120
      },
      {
        title: 'sanityCheck.configurations.grid.subType',
        field: 'subType',
        template: true,
        sortable: false,
        width: 120
      },
      {
        title: 'sanityCheck.configurations.grid.basis',
        field: 'basis',
        template: true,
        sortable: false,
        width: 120
      },
      {
        title: 'sanityCheck.configurations.grid.pending',
        field: 'pending',
        defaultColumnTemplate: DefaultColumnTemplateType.selection,
        disabled: true,
        sortable: false,
        width: 60
      },
      {
        title: 'sanityCheck.configurations.grid.registered',
        field: 'registered',
        defaultColumnTemplate: DefaultColumnTemplateType.selection,
        disabled: true,
        sortable: false,
        width: 60
      },
      {
        title: 'sanityCheck.configurations.grid.dead',
        field: 'dead',
        defaultColumnTemplate: DefaultColumnTemplateType.selection,
        disabled: true,
        sortable: false,
        width: 60
      },
      {
        title: 'sanityCheck.configurations.grid.inUse',
        field: 'inUse',
        defaultColumnTemplate: DefaultColumnTemplateType.selection,
        disabled: true,
        sortable: false,
        width: 60
      },
      {
        title: 'sanityCheck.configurations.grid.deferred',
        field: 'deferred',
        defaultColumnTemplate: DefaultColumnTemplateType.selection,
        disabled: true,
        sortable: false,
        width: 60
      },
      {
        title: 'sanityCheck.configurations.grid.informational',
        field: 'informational',
        defaultColumnTemplate: DefaultColumnTemplateType.selection,
        disabled: true,
        sortable: false,
        width: 60
      }
    ];

    return columns;
  };

  private readonly insertIf = (condition, ...element): any => {
    return condition ? element : [];
  };

  private readonly getActions = (type: 'case' | 'name'): Array<IpxBulkActionOptions> => {
    const actions = [
      ...this.insertIf(this.canUpdate(type), {
        ...new IpxBulkActionOptions(),
        id: 'edit',
        icon: 'cpa-icon cpa-icon-edit',
        text: 'bulkactionsmenu.edit',
        enabled$: this.singleSelected$,
        click: this.edit
      }),
      ...this.insertIf(this.canDelete(type),
        {
          ...new IpxBulkActionOptions(),
          id: 'Delete',
          icon: 'cpa-icon cpa-icon-trash',
          text: 'bulkactionsmenu.delete',
          enabled$: this.anySelected$,
          click: (resultGrid: IpxKendoGridComponent) => {
            this.notificationService.confirmDelete({
              message: 'sanityCheck.configurations.grid.deleteConfirmation'
            }).then(() => {
              const rowSelectionParams = resultGrid.getRowSelectionParams();
              const selectedIds = rowSelectionParams.rowSelection;
              this.service.deleteSanityCheck$(this.matchType, selectedIds).subscribe((response) => {
                if (response) {
                  this.notificationService.success('sanityCheck.configurations.grid.deleteSuccess');
                  this.gridOptions._search();
                }
              });
            });
          }
        })];

    return actions;
  };

  private readonly getDataToSearchNameRule = (model: any) => {
    const searchModel = new DataValidationSearchModel({
      nameCharacteristics: {
        nameGroup: model.nameGroup?.key,
        name: model.name?.key,
        jurisdiction: model.jurisdiction?.code,
        category: model.category?.key,
        isLocal: !model.applyTo || model.applyTo === '' ? null : model.applyTo === 'local-clients' ? 1 : 0,
        tableColumn: model.tableColumn?.key,
        instructionType: model.instructionType?.code,
        characteristics: model.characteristic?.id,
        isSupplierOnly: model.typeIsSupplierOnly,
        entityType: {
          isOrganisation: model.typeIsOrganisation,
          isIndividual: model.typeIsIndividual,
          isClientOnly: model.typeIsClientOnly,
          isStaff: model.typeIsStaff
        }
      },
      ruleOverview: {
        inUse: model.inUse === true ? true : null,
        deferred: model.deferred === true ? true : null,
        displayMessage: model.displayMessage,
        notes: model.notes,
        ruleDescription: model.ruleDescription,
        informationOnly: model.informationOnly === true ? true : null,
        sanityCheckSql: model.sanityCheckSql != null ? model.sanityCheckSql.key : null,
        mayBypassError: model.mayBypassError != null ? model.mayBypassError.key : null
      },
      other: {
        tableColumn: model.tableColumn != null ? model.tableColumn.key : null
      },
      standingInstruction: {
        instructionType: model.instructionType != null ? model.instructionType.code : null,
        characteristics: model.characteristic != null ? model.characteristic.id : null
      }
    });

    return searchModel;
  };

  private readonly getDataToSearchCaseRule = (model: any): any => {
    const searchModel = new DataValidationSearchModel({
      caseCharacteristics: {
        caseCategory: model.caseCategory?.code,
        caseType: model.caseType?.code,
        propertyType: model.propertyType?.code,
        jurisdiction: model.jurisdiction?.code,
        subType: model.subType != null ? model.subType.code : null,
        basis: model.basis != null ? model.basis.code : null,
        statusIncludePending: model.statusIncludePending === true,
        statusIncludeRegistered: model.statusIncludeRegistered === true,
        statusIncludeDead: model.statusIncludeDead === true,
        office: model.caseOffice != null ? model.caseOffice.key : null,
        applyTo: !model.applyTo || model.applyTo === '' ? null : model.applyTo === 'local-clients' ? 1 : 0,
        caseCategoryExclude: model.caseCategoryExclude === true,
        caseTypeExclude: model.caseTypeExclude === true,
        jurisdictionExclude: model.jurisdictionExclude === true,
        propertyTypeExclude: model.propertyTypeExclude === true,
        subTypeExclude: model.subTypeExclude === true,
        basisExclude: model.basisExclude === true
      },
      event: {
        includeOccurred: model.eventIncludeOccurred === true,
        includeDue: model.eventIncludeDue === true,
        eventNo: model.event != null ? model.event.key : null
      },
      ruleOverview: {
        inUse: model.inUse === true ? true : null,
        deferred: model.deferred === true ? true : null,
        displayMessage: model.displayMessage,
        notes: model.notes,
        ruleDescription: model.ruleDescription,
        informationOnly: model.informationOnly === true ? true : null,
        sanityCheckSql: model.sanityCheckSql != null ? model.sanityCheckSql.key : null,
        mayBypassError: model.mayBypassError != null ? model.mayBypassError.key : null
      },
      other: {
        tableColumn: model.tableColumn != null ? model.tableColumn.key : null

      },
      caseName: {
        nameGroup: model.nameGroup != null ? model.nameGroup.key : null,
        name: model.name != null ? model.name.key : null,
        nameType: model.nameType != null ? model.nameType.code : null
      },
      standingInstruction: {
        instructionType: model.instructionType != null ? model.instructionType.code : null,
        characteristics: model.characteristic != null ? model.characteristic.id : null
      }
    });

    return searchModel;
  };
  readonly subscribeGridChange = (): void => {
    this.cdf.detectChanges();

    if (this.gridChangeSubscription) {
      this.gridChangeSubscription.unsubscribe();
    }

    if (this.canDelete(this.matchType) || this.canUpdate(this.matchType)) {
      this.gridChangeSubscription = this.grid.rowSelectionChanged
        .pipe(takeUntil(this.destroy$))
        .subscribe((event) => {
          const res = event.rowSelection?.length;
          this.selectionCountSubject.next(res);
        });
    }
  };

  readonly edit = (resultGrid: IpxKendoGridComponent): void => {
    const items = resultGrid.allSelectedItem;
    if (items?.length > 1 || items?.length === 0) { return; }

    this.navigateToEdit(items[0]);
  };

  readonly navigateToEdit = (dataItem: any): void => {
    this.stateService.go('sanityCheckMaintenanceEdit', {
      matchType: this.matchType,
      id: dataItem.id,
      rowKey: dataItem.rowKey
    });
  };
}