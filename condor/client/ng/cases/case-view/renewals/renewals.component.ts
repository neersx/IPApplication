import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { TopicContract } from 'shared/component/topics/ipx-topic.contract';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { CaseDetailService } from '../case-detail.service';
import { Names } from './renewals-models';

@Component({
    selector: 'ipx-case-view-renewals',
    templateUrl: './renewals.html',
    styleUrls: ['./renewals.component.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class RenewalsComponent implements TopicContract, OnInit {
    @ViewChild('renewalDetailTemplate', { static: true }) renewalDetailTemplate: TemplateRef<any>;
    topic: Topic;
    @Input() data: any;
    gridOptions: IpxGridOptions;
    renewalNamesData: Array<Names>;
    caseId: number;
    isLoaded: boolean | false;
    showWebLink: boolean | false;

    ngOnInit(): void {
        this.showWebLink = (this.topic.params as RenewalsTopicParams).showWebLink;
        this.data = {
            caseStatus: this.topic.params.viewData.caseStatus,
            renewalStatus: this.topic.params.viewData.renewalStatus
        };
        this.caseId = this.topic.params.viewData.caseId;
        this.gridOptions = this.buildGridOptions();
        this.service
            .getCaseRenewalsData$(this.caseId, this.topic.params.viewData.screenControl)
            .subscribe(details => {
                this.data = { ...this.data, ...details };
                this.isLoaded = true;
                this.cdr.detectChanges();
                if (this.data.renewalNames) {
                    this.gridOptions._search();
                }
            });
    }

    buildGridOptions = (): IpxGridOptions => {
        return {
            manualOperations: true,
            sortable: true,
            selectable: {
                mode: 'single'
            },
            autobind: false,
            showGridMessagesUsingInlineAlert: false,
            read$: () => { return of(this.data.renewalNames).pipe(delay(100)); },
            detailTemplate: this.renewalDetailTemplate,
            detailTemplateShowCondition: (dataItem: any): boolean => {
                return dataItem.canView;
            },
            gridMessages: {
                noResultsFound: 'grid.messages.noItems',
                performSearch: 'grid.messages.noItems'
            },
            columns: this.getColumns(),
            itemName: 'caseview.renewals.names',
            itemTemplate: new Names(),
            persistSelection: false,
            reorderable: true,
            navigable: false
        };
    };

    encodeLinkData = (data: any) => {
        return 'api/search/redirect?linkData=' + encodeURIComponent(JSON.stringify({
            nameKey: data
        }));
    };
    private readonly getColumns = (): Array<GridColumnDefinition> => {
        const columns = [
            {
                title: 'caseview.renewals.names.type',
                field: 'type',
                template: true,
                sortable: true,
                width: 170
            },
            {
                title: '',
                field: 'shouldCheckRestrictions',
                template: true,
                sortable: false,
                width: 20
            },
            {
                title: 'caseview.renewals.names.name',
                field: 'nameAndCode',
                template: true,
                sortable: true,
                width: 170
            },
            {
                title: 'caseview.renewals.names.nameVariant',
                field: 'nameVariant',
                template: true,
                sortable: true,
                width: 170
            },
            {
                title: 'caseview.renewals.names.attention',
                field: 'attention',
                template: true,
                sortable: true,
                width: 130
            },
            {
                title: 'caseview.renewals.names.reference',
                field: 'reference',
                template: true,
                sortable: true,
                width: 120
            }
        ];

        if (!this.topic.params.viewData.displayNameVariants) {
            columns.splice(3, 1);
        }

        return columns;
    };
    constructor(private readonly service: CaseDetailService, private readonly cdr: ChangeDetectorRef) {
    }
}

export class RenewalsTopic extends Topic {
    readonly key = 'renewals';
    readonly title = 'caseview.renewals.header';
    readonly component = RenewalsComponent;
    constructor(public params: RenewalsTopicParams) {
        super();
    }
}

export class RenewalsTopicParams extends TopicParam {
    showWebLink: boolean;
}