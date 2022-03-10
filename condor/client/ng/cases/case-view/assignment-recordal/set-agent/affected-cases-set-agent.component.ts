import { ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { KnownNameTypes } from 'names/knownnametypes';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Observable, of, Subject, Subscription } from 'rxjs';
import { delay, map, take, takeUntil } from 'rxjs/operators';
import { NameFilteredPicklistScope } from 'search/case/case-search-topics/name-filtered-picklist-scope';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import { AffectedCasesService } from '../affected-cases.service';
import { AffectedCasesSetAgentService } from './affected-cases-set-agent.service';

@Component({
    selector: 'ipx-affected-cases-set-agent',
    templateUrl: './affected-cases-set-agent.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class AffectedCasesSetAgentComponent implements OnInit, OnDestroy {
    @Input() affectedCases: Array<any>;
    @Input() mainCaseId: number;
    @Input() isAllPageSelect: boolean;
    @Input() filterParams: any;
    @Input() deselectedRows: any;
    gridOptions: IpxGridOptions;
    onClose$ = new Subject();
    isSaveDisabled = true;
    nameType: string;
    caseRefSubscription: Subscription;

    @Input() showWebLink: Boolean;
    namePickListExternalScope: NameFilteredPicklistScope;
    @ViewChild('agentsGrid', { static: false }) grid: IpxKendoGridComponent;
    formData = {
        agent: null,
        isCaseNameSet: true
    };
    caseReference: string;
    isSaving: boolean;

    constructor(
        private readonly service: AffectedCasesSetAgentService,
        private readonly knownNameTypes: KnownNameTypes,
        private readonly translate: TranslateService,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly sbsModalRef: BsModalRef,
        private readonly affectedCasesService: AffectedCasesService,
        private readonly destroy$: IpxDestroy,
        private readonly shortcutsService: IpxShortcutsService) { }

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
        this.namePickListExternalScope = new NameFilteredPicklistScope(
            this.knownNameTypes.Agent,
            this.translate.instant('picklist.agent'),
            false
        );
        this.caseRefSubscription = this.service.getCaseReference(this.mainCaseId).subscribe((res: any) => {
            this.caseReference = res.caseRef;
            this.nameType = res.nameType;
        });
        this.handleShortcuts();
    }

    handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.SAVE, (): void => { if (!this.isSaveDisabled) { this.onSave(); } }],
            [RegisterableShortcuts.REVERT, (): void => { this.close(); }]]);
        this.shortcutsService.observeMultiple$([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key)) {
                    shortcutCallbacksMap.get(key)();
                }
            });
    }

    ngOnDestroy(): void {
        this.caseRefSubscription.unsubscribe();
    }

    buildGridOptions(): IpxGridOptions {
        // tslint:disable-next-line: no-this-assignment
        const vm = this;

        return {
            autobind: true,
            navigable: true,
            pageable: false,
            reorderable: false,
            sortable: false,
            filterable: false,
            read$: () => {
                if (vm.isAllPageSelect && !vm.affectedCases) {
                    const data = vm.affectedCasesService.getAffectedCases(vm.mainCaseId, null, vm.filterParams);

                    return vm.convertToGridData(data);
                }

                return of(vm.affectedCases).pipe(delay(100));
            },
            columns: vm.getColumns()
        };
    }

    private readonly convertToGridData = (results: Observable<any>): Observable<any> => {

        return results.pipe(map(data => {
            return {
                data: this.deselectedRows ? data.rows.filter((k) => {
                    return !this.deselectedRows.map(x => x.rowKey).includes(k.rowKey);
                }) : data.rows,
                pagination: { total: data.totalRows }
            };
        }
        ));
    };

    onAgentChanged(event: any): void {
        this.isSaveDisabled = !(!!event && event.key);
    }

    onSave = (): any => {
        this.isSaving = true;
        this.isSaveDisabled = true;
        const rows = this.grid.getCurrentData().map(x => x.rowKey);
        const hasInternalRows = this.grid.getCurrentData().filter(x => x.caseId && x.caseId !== null);
        const isCaseNameSet = this.formData.isCaseNameSet;
        this.service.setAgent(this.formData.agent.key, this.mainCaseId, isCaseNameSet, rows).subscribe((response) => {
            this.isSaving = false;
            if (response.result === 'success') {
                this.sbsModalRef.hide();
                this.onClose$.next(isCaseNameSet && hasInternalRows.length > 0 ? 'background' : 'success');
            }
        });
    };

    close = (): any => {
        if (!this.isSaveDisabled) {
            const modal = this.ipxNotificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.sbsModalRef.hide();
                    this.onClose$.next(false);
                });
        } else {
            this.sbsModalRef.hide();
            this.onClose$.next(false);
        }
    };

    encodeLinkData = (data: any) =>
        'api/search/redirect?linkData=' +
        encodeURIComponent(JSON.stringify(data));

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [
            {
                title: 'caseview.affectedCases.columns.caseRef',
                field: 'caseReference',
                template: true,
                sortable: false
            }, {
                title: 'caseview.affectedCases.columns.jurisdiction',
                field: 'country',
                sortable: false
            }, {
                title: 'caseview.affectedCases.columns.officialNo',
                field: 'officialNo',
                template: true,
                sortable: false
            }, {
                title: 'caseview.affectedCases.columns.currentOwner',
                field: 'owner',
                sortable: false
            }, {
                title: 'caseview.affectedCases.columns.foreignAgent',
                field: 'agent',
                template: true,
                sortable: false
            }, {
                title: 'caseview.affectedCases.columns.propertyType',
                field: 'propertyType',
                sortable: false
            }, {
                title: 'caseview.affectedCases.columns.caseStatus',
                field: 'caseStatus',
                sortable: false
            }];

        return columns;
    };
}