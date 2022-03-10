import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/core';
import { CaseDetailService } from 'cases/case-view/case-detail.service';
import { CommonUtilityService } from 'core/common.utility.service';
import { QuickNavModel, RightBarNavService } from 'rightbarnav/rightbarnav.service';
import { ReportExportFormat } from 'search/results/report-export.format';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition, GridQueryParameters } from 'shared/component/grid/ipx-grid.models';
import { SanityCheckResultsService } from './sanity-check-results.service';

@Component({
  selector: 'sanity-check-results',
  templateUrl: './sanity-check-results.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})

export class SanityCheckResultsComponent implements OnInit {

  @Input() stateParams: {
    id: number
  };

  @ViewChild('ipxActionStatusColumn', { static: true }) statusCol: TemplateRef<any>;
  @ViewChild('groupDetailTemplate', { static: true }) groupDetailTemplate: TemplateRef<any>;
  defaultProgram: string;
  headerTitle: string;
  queryParams: any;

  ngOnInit(): void {
    this.headerTitle = this.commonService.formatString('{0} {1}', '0', this.translate.instant('sanityCheck.pageTitle'));
    this.gridOptions = this.buildGridOptions();
    this.setContextNavigation();
    this.cdref.detectChanges();
  }

  gridOptions: IpxGridOptions;
  constructor(private readonly commonService: CommonUtilityService,
    readonly cdref: ChangeDetectorRef,
    readonly sanityCheckResultsService: SanityCheckResultsService,
    readonly caseService: CaseDetailService,
    readonly stateService: StateService,
    private readonly translate: TranslateService,
    private readonly rightBarNavService: RightBarNavService) {
  }

  private readonly buildGridOptions = (): IpxGridOptions => {

    const options: IpxGridOptions = {
      selectable: {
        mode: 'single'
      },
      groupable: true,
      sortable: true,
      autobind: true,
      groupDetailTemplate: this.groupDetailTemplate,
      read$: (queryParams: GridQueryParameters) => {
        const results = this.sanityCheckResultsService.getSanityCheckResults(this.stateParams.id, queryParams);
        results.subscribe(result => {
          this.headerTitle = result.pagination.total > 1 ? this.commonService.formatString('{0} {1}', result.pagination.total.toString(), this.translate.instant('sanityCheck.multipleResults')) :
            this.commonService.formatString('{0} {1}', result.pagination.total.toString(), this.translate.instant('sanityCheck.pageTitle'));
          this.cdref.markForCheck();
        });

        return results;
      },
      columns: this.getColumns(),
      persistSelection: false,
      reorderable: true,
      navigable: false,
      pageable: true
    };

    return options;
  };

  private readonly getColumns = (): Array<GridColumnDefinition> => {
    const columns = [{
      field: 'status',
      template: true,
      title: 'sanityCheck.status',
      width: 70
    }, {
      field: 'caseReference',
      title: 'sanityCheck.caseReference',
      width: 100,
      template: true
    },
    {
      field: 'caseOffice',
      title: 'sanityCheck.caseOffice',
      width: 100
    },
    {
      field: 'staffName',
      title: 'sanityCheck.staff',
      width: 150
    },
    {
      field: 'signatoryName',
      title: 'sanityCheck.signatory',
      width: 150
    },
    {
      field: 'displayMessage',
      title: 'sanityCheck.displayMessage',
      template: true
    }];

    return columns;
  };

  private readonly setContextNavigation = () => {
    const context: any = {};
    const exportUrl = 'api/search/case/sanitycheck/export';
    context.contextEmail = new QuickNavModel(null, {
      id: 'exportExcel',
      icon: 'cpa-icon-file-excel-o', tooltip: 'sanityCheck.exportToExcel', click: () => {
        this.commonService.export(exportUrl, { processId: this.stateParams.id, exportFormat: ReportExportFormat.Excel });
      }
    });
    context.contextPDF = new QuickNavModel(null, {
      id: 'exportPDF',
      icon: 'cpa-icon-file-pdf-o', tooltip: 'sanityCheck.exportToPdf', click: () => {
        this.commonService.export(exportUrl, { processId: this.stateParams.id, exportFormat: ReportExportFormat.PDF });
      }
    });
    context.contextWord = new QuickNavModel(null, {
      id: 'exportWord',
      icon: 'cpa-icon-file-word-o', tooltip: 'sanityCheck.exportToWord', click: () => {
        this.commonService.export(exportUrl, { processId: this.stateParams.id, exportFormat: ReportExportFormat.Word });
      }
    });
    this.rightBarNavService.registercontextuals(context);
  };

  close = () => {
    window.history.go(-1);
  };

  getFlagStyle(status: string): {
    [key: string]: string;
  } {
    let colorCode = '';

    switch (status) {
      case 'Error':
        colorCode = '#ff0000';
        break;
      case 'Information':
        colorCode = '#ffff00';
        break;
      case 'ByPassError':
        colorCode = '#ffa500';
        break;
      default: break;
    }

    return {
      color: colorCode
    };
  }
}