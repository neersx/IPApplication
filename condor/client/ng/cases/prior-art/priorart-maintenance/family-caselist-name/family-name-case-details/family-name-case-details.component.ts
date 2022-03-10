import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { PriorArtService } from 'cases/prior-art/priorart.service';
import { LocalSettings } from 'core/local-settings';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition, GridQueryParameters } from 'shared/component/grid/ipx-grid.models';

@Component({
    selector: 'ipx-family-name-case-details',
    templateUrl: './family-name-case-details.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class FamilyNameCaseDetailsComponent implements OnInit {
    caseDetailsGridOptions: IpxGridOptions;
    queryParams: GridQueryParameters;
    @Input() searchOptions: any;
    @Input() priorArtId: Number;

    constructor(private readonly service: PriorArtService, readonly localSettings: LocalSettings) { }

    ngOnInit(): void {
        this.caseDetailsGridOptions = this.buildCaseDetailsGridOptions();
    }

    buildCaseDetailsGridOptions(): IpxGridOptions {
        const pageSizeSetting = this.localSettings.keys.priorart.linkedFamilyCaseDetailsGrid;

        return {
            autobind: true,
            pageable: {
                pageSizeSetting,
                pageSizes: [5, 10, 20, 50]
            },
            read$: (queryParams: GridQueryParameters) => {
                this.queryParams = queryParams;

                return this.service.getFamilyCaseListDetails$(this.searchOptions, this.queryParams);
            },
            columns: this.getCaseDetailsColumns()
        };
    }

    private readonly getCaseDetailsColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [
            {
                title: 'priorart.maintenance.step4.caseDetails.columns.caseRef',
                field: 'irn',
                template: true
            },
            {
                title: 'priorart.maintenance.step4.caseDetails.columns.officialNumber',
                field: 'officialNumber'
            },
            {
                title: 'priorart.maintenance.step4.caseDetails.columns.jurisdiction',
                field: 'jurisdiction'
            }];

        return columns;
    };

}
