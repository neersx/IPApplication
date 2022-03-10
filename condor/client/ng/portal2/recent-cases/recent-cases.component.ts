import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { DateService } from 'ajs-upgraded-providers/date-service.provider';
import { AppContextService } from 'core/app-context.service';
import { LocalSetting, LocalSettings } from 'core/local-settings';
import { RecentCasesService } from 'portal2/recent-cases.service';
import { map, take } from 'rxjs/operators';
import { SearchResult } from 'search/results/search-results.model';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition, GridQueryParameters } from 'shared/component/grid/ipx-grid.models';

@Component({
  selector: 'ipx-recent-cases',
  templateUrl: './recent-cases.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RecentCasesComponent implements OnInit {
  responseRows: Array<any>;
  responseColumns: Array<any>;
  expandSetting: LocalSetting;
  @Input() rowKey: string;
  @ViewChild('columnTemplate', { static: true }) template: any;
  gridOptions: IpxGridOptions;
  loaded: boolean;
  totalRecords?: Number;
  filter: Array<{ anySearch: { operator: number; value: string; }; }>;
  context: string;
  dateFormat: any;
  searchTerm: any;
  queryKey?: number;
  isSavedSearch: any;
  showWebLink: boolean;
  selectedCaseKey: String | undefined;
  defaultProgram: String;
  showRecentCases = false;

  constructor(
    private readonly service: RecentCasesService,
    private readonly dateService: DateService,
    private readonly appContextService: AppContextService,
    private readonly cdRef: ChangeDetectorRef,
    private readonly localSettings: LocalSettings
  ) { }

  ngOnInit(): void {
    this.dateFormat = this.dateService.dateFormat;
    this.context = 'recentCases';
    this.expandSetting = this.localSettings.keys.recentCases.expanded;

    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe((ctx: any) => {
        this.showWebLink = ctx.user.permissions.canShowLinkforInprotechWeb;
        this.showRecentCases = ctx.user.permissions.canViewRecentCases;
      });
    if (this.showRecentCases) {
      this.initializeRecentCases();
    }
  }

  initializeRecentCases = () => {
    const queryParams = { skip: null, take: null };
    this.service.get(queryParams).toPromise()
      .then((response) => {
        if (response) {
          this.responseColumns = response.columns;
          this.responseRows = response.rows;
          const searchResultColumns = this.buildColumns(response);
          this.gridOptions = this.buildGridOptions(searchResultColumns);
          this.loaded = true;
          this.cdRef.markForCheck();
        }
      });

    this.service.getDefaultProgram().subscribe((result) => {
      this.defaultProgram = result;
      this.cdRef.markForCheck();
    });
  };

  private readonly buildGridOptions = (resultColumns: Array<GridColumnDefinition>): IpxGridOptions => {
    return {
      sortable: true,
      selectable: true,
      rowClass: (context) => {
        let returnValue = '';
        if (context.dataItem && context.dataItem.caseKey === this.selectedCaseKey) {
          returnValue += 'selected ';
        }

        return returnValue;
      },
      read$: (queryParams: GridQueryParameters) => {
        return this.service.get(queryParams)
          .pipe(map((data: any) => {
            return {
              data: data.rows,
              pagination: { total: data.totalRows }
            };
          }
          ));
      },
      onDataBound: (data: any) => {
        if (data.data.length > 0) {
          let caseKey = null;
          if (this.rowKey) {
            const selectedRow = data.data.find(r => r.rowKey === this.rowKey);
            caseKey = selectedRow ? selectedRow.caseKey : caseKey;
          }
          this.selectedCaseKey = caseKey;
        } else {
          this.selectedCaseKey = null;
        }
      },
      columns: resultColumns
    };
  };

  buildColumns = (searchResult: SearchResult): Array<GridColumnDefinition> => {
    if (searchResult.columns && searchResult.columns.length > 0) {
      const columns = new Array<GridColumnDefinition>();
      searchResult.columns.forEach(c => {
        columns.push({
          title: c.title,
          template: this.template,
          templateExternalContext: { id: c.id, isHyperlink: c.isHyperlink, format: c.format },
          sortable: true,
          field: c.fieldId,
          filter: c.filterable
        });
      });

      return columns;
    }

    return [];
  };

  encodeLinkData(data): string {
    return 'api/search/redirect?linkData=' + encodeURIComponent(JSON.stringify(data));
  }
}
