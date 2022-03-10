import { ChangeDetectionStrategy, Component, EventEmitter, Input, OnInit, Output, TemplateRef, ViewChild } from '@angular/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { LocalSettings } from 'core/local-settings';
import { of } from 'rxjs';
import { delay, take } from 'rxjs/operators';
import { GridHelper } from 'shared/component/grid/ipx-grid-helper';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { PriorArtDetailsComponent } from '../priorart-details/priorart-details.component';
import { PriorArtSearchResult } from '../priorart-search/priorart-search-model';
@Component({
    selector: 'ipx-priorart-not-found-result',
    templateUrl: './priorart-not-found-result.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class PriorartNotFoundResultComponent implements OnInit {
    @Input() data: Array<PriorArtSearchResult>;
    @ViewChild('dataDetailTemplate', { static: true }) dataDetailTemplate: TemplateRef<any>;
    @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
    @ViewChild('dataDetailComponent', { static: false }) dataDetailComponent: PriorArtDetailsComponent;
    @Input() translationsList: any = {};
    gridOptions: IpxGridOptions;
    @Output() readonly onRefreshGrid = new EventEmitter();
    constructor(private readonly notificationService: IpxNotificationService, private readonly successNotificationService: NotificationService, private readonly localSettings: LocalSettings) {
    }
    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
    }

    buildGridOptions(): IpxGridOptions {
        return {
            selectable: {
                mode: 'single'
            },
            sortable: true,
            autobind: true,
            read$: () => {
                return of({
                    data: this.data,
                    pagination: {total: this.data.length}
                }).pipe(delay(100));
            },
            onDataBound: () => {
                const settings = this.localSettings.keys.priorart.search.notFoundPageSize;
                this.pageChanged({skip: 0, take: settings.getLocal});
            },
            columns: this.getColumns(),
            persistSelection: false,
            reorderable: true,
            detailTemplate: this.dataDetailTemplate,
            navigable: true,
            pageable: {
                pageSizeSetting: this.localSettings.keys.priorart.search.notFoundPageSize,
                pageSizes: [10, 20]
            },
            manualOperations: true
        };
    }

    onCollapse(event): void {
        if (event.dataItem.hasChanges) {
            event.prevented = true;
            const modal = this.notificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.dataDetailComponent.revertForm(event);
                    event.dataItem.hasChanges = false;
                    const collapseElement = this.grid.wrapper.wrapper.nativeElement.querySelector('.k-hierarchy-cell .k-minus');
                    if (collapseElement) {
                        collapseElement.click();
                    }
                });
        }
    }

    onSaveData(event): void {
        if (event.success) {
            this.successNotificationService.success();
            const collapseElement = this.grid.wrapper.wrapper.nativeElement.querySelector('.k-hierarchy-cell .k-minus');
            if (collapseElement) {
                collapseElement.click();
            }
            this.data = [];
            this.grid.search();
            this.onRefreshGrid.emit(event);
        }
    }

    private readonly getColumns = (): Array<GridColumnDefinition> => {
        const columns = [
            {
                title: 'priorart.notFound.reference',
                field: 'reference',
                template: true,
                width: 200
            },
            {
                title: 'priorart.notFound.jurisdiction',
                field: 'countryName',
                template: true,
                width: 200
            },
            {
                title: 'priorart.notFound.kindCode',
                field: 'kind',
                template: true
            }
        ];

        return columns;
    };

    pageChanged(event: { skip: number, take: number }): void {
        GridHelper.manualPageChange(this.grid, this.data, event.skip, event.take);
    }
}