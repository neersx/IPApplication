import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { LocalSettings } from 'core/local-settings';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { ScreenDesignerViewData } from '../../screen-designer.service';
import { SearchService } from './search.service';

export class SearchStateParams {
  rowKey: string;
  isLevelUp: boolean;
}

@Component({
  selector: 'app-screen-designer',
  templateUrl: './search.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  animations: [
    slideInOutVisible
  ]
})
export class ScreenDesignerSearchComponent implements OnInit {
  @Input() viewData: ScreenDesignerViewData;
  @Input() stateParams: SearchStateParams;
  @ViewChild('fieldCol', { static: true }) fieldCol: TemplateRef<any>;
  @ViewChild('searchResultsGrid', { static: true }) searchResultsGrid: IpxKendoGridComponent;
  @ViewChild('criteriaDetailsTemplate', { static: true }) criteriaDetailsTemplate: any;
  @ViewChild('inheritedDetailsTemplate', { static: true }) inheritedDetailsTemplate: any;
  matchType: string;
  criteria: any;
  filter: any;
  selectedRowKey: string;
  queryParams: any;
  searchGridOptions: IpxGridOptions;
  showSearchBar = true;
  constructor(private readonly cdr: ChangeDetectorRef, public searchService: SearchService, readonly localSettings: LocalSettings) {
    this.matchType = 'characteristic';
  }

  ngOnInit(): void {
    this.initGridOption();
    const rowKey = this.stateParams.rowKey;
        if (rowKey && this.stateParams.isLevelUp) {
            // this.searchService.temporarilyReturnNextRecordSetFromCache();
            this.searchGridOptions.selectedRecords = {
                page: this.searchService.getCurrentPageIndex(rowKey)
            };
            this.selectedRowKey = rowKey;
            this.criteria = this.searchService.getRecentSearchCriteria();
        }
    this.matchType = this.searchService.getSelectedSearchType() || 'characteristic';
    this.cdr.detectChanges();
  }
  dataItemClicked = (dataItem): void => {
    this.selectedRowKey = dataItem.rowKey;
  };

  search = (value: any): void => {
    this.filter = null;
    this.searchService.setSelectedSearchType(this.matchType);
    this.searchResultsGrid.clearFilters();
    this.searchResultsGrid.dataOptions.gridMessages.noResultsFound = 'noResultsFound';
    if (value.matchType !== 'exact-match') {
      this.searchResultsGrid.dataOptions.gridMessages.noResultsFound = 'screenDesignerCases.search.noRecordsBestMatch';
    }
    this.criteria = value;
    this.searchService.setRecentSearchCriteria(value);
    this.searchResultsGrid.search();
  };

  clear = (): void => {
    this.searchResultsGrid.clear();
  };

  initGridOption(): void {
    this.searchGridOptions = {
      filterable: true,
      navigable: true,
      sortable: true,
      autobind: false,
      reorderable: true,
      selectable: true,
      gridMessages: {},
      rowClass: (context) => {
        let returnValue = '';
        if (context.dataItem && context.dataItem.rowKey === this.selectedRowKey) {
            returnValue += 'selected ';
        }

        return returnValue;
      },
      pageable: {
        pageSize: 10,
        pageSizes: [10, 20, 50, 100, 250]
      },
      read$: (queryParams: any) => {
        this.queryParams = queryParams;

        return this.searchService.getCaseCriterias$(this.matchType, this.criteria, queryParams);
      },

      filterMetaData$: (column) => {
        if (this.matchType === 'criteria') {
          return this.searchService.getColumnFilterDataByIds$(this.criteria, column.field, this.queryParams);
        }

        return this.searchService
          .getColumnFilterData$(this.criteria, column.field, this.queryParams);
      },
      columnSelection: {
        localSetting: this.localSettings.keys.screenDesigner.search.columnsSelection
      },
      columns: [{
        title: '',
        // locked: true,
        sortable: false,
        field: 'isInherited',
        width: 28,
        fixed: true,
        template: this.inheritedDetailsTemplate
      }, {
        // locked: true,
        title: '',
        sortable: false,
        field: 'isProtected',
        width: 28,
        fixed: true,
        defaultColumnTemplate: DefaultColumnTemplateType.protected
      }, {
        // locked: true,
        title: 'Criteria No.',
        field: 'id',
        width: 110,
        fixed: true,
        template: this.criteriaDetailsTemplate
      }, {
        title: 'Criteria Name',
        field: 'criteriaName',
        width: 200
      }, {
        title: 'Office',
        field: 'office',
        width: 120,
        hidden: !this.viewData.hasOffices,
        defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
      }, {
        title: 'Program',
        field: 'program',
        width: 150,
        filter: true,
        defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
      }, {
        title: 'Jurisdiction',
        field: 'jurisdiction',
        width: 150,
        filter: true,
        defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
      }, {
        title: 'Case Type',
        field: 'caseType',
        width: 200,
        defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
      }, {
        title: 'propertyType',
        field: 'propertyType',
        width: 150,
        defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
      }, {
        title: 'Case Category',
        field: 'caseCategory',
        width: 200,
        defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
      }, {
        title: 'Sub Type',
        field: 'subType',
        width: 200,
        defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
      }, {
        title: 'Basis',
        field: 'basis',
        width: 200,
        defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
      }, {
        title: 'In Use',
        field: 'inUse',
        width: 100,
        defaultColumnTemplate: DefaultColumnTemplateType.selection,
        disabled: true
      }, {
        title: 'Profile Name',
        field: 'profile',
        width: 100,
        defaultColumnTemplate: DefaultColumnTemplateType.codeDescription
      }]
    };
  }

  onRowAdded = (): void => {

    return;
  };

  openCharacteristicModal = (): void => {

    return;
  };
}
