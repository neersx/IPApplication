import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, OnInit, Output, TemplateRef, ViewChild } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { RootScopeService } from 'ajs-upgraded-providers/rootscope.service';
import { LocalSettings } from 'core/local-settings';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BehaviorSubject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { ValidationError } from 'shared/component/forms/validation-error';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { DefaultColumnTemplateType, GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import { Topic, TopicParam } from 'shared/component/topics/ipx-topic.model';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import { MaintenanceTopicContract } from '../base/case-view-topics.base.component';
import { CaseDetailService } from '../case-detail.service';
import { caseViewTopicTitles } from '../case-view-topic-titles';
import { DesignElementsMaintenanceComponent } from './design-elements-maintenance/design-elements-maintenance.component';
import { DesignElementImage, DesignElementItems } from './design-elements.model';
import { DesignElementsService } from './design-elements.service';

@Component({
    selector: 'ipx-caseview-design-elements',
    templateUrl: './design-elements.component.html',
    styleUrls: ['./design-elements.styles.scss'],
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class DesignElementsComponent implements OnInit, MaintenanceTopicContract {
    topic: Topic;
    gridOptions: IpxGridOptions;
    isHosted = false;
    rowEditUpdates: { [rowKey: string]: any };
    canMaintainCase = false;
    maintainFormGroup$ = new BehaviorSubject<FormGroup>(null);
    skip = 0;
    @Output() readonly pageChanged = new EventEmitter();
    @ViewChild('detailTemplate', { static: true }) detailTemplate: TemplateRef<any>;
    @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;

    constructor(readonly localSettings: LocalSettings,
        readonly service: DesignElementsService,
        private readonly modalService: IpxModalService,
        private readonly formBuilder: FormBuilder,
        private readonly cdRef: ChangeDetectorRef,
        private readonly rootScopeService: RootScopeService,
        private readonly caseDetailService: CaseDetailService,
        private readonly notificationService: NotificationService,
        private readonly destroy$: IpxDestroy,
        private readonly shortcutsService: IpxShortcutsService) { }

    ngOnInit(): void {
        this.isHosted = this.rootScopeService.isHosted;
        if (this.topic.setErrors) {
            this.topic.setErrors(false);
        }
        this.topic.hasChanges = false;
        this.rowEditUpdates = {};
        this.canMaintainCase = this.isHosted && this.topic.params.viewData.canMaintainCase;
        this.gridOptions = this.buildGridOptions();
        this.caseDetailService.resetChanges$.subscribe((val: boolean) => {
            if (val) {
                this.resetForms();
            }
        });
        this.caseDetailService.errorDetails$.subscribe(errs => {
            this.setErrors(errs);
        });
        this.handleShortcuts();
    }

    handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.ADD, (): void => { if (this.isHosted) { this.grid.onAdd(); } }]]);
        this.shortcutsService.observeMultiple$([RegisterableShortcuts.ADD])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key)) {
                    shortcutCallbacksMap.get(key)();
                }
            });
    }

    onPageChanged(): void {
        this.grid.closeEditedRows(this.skip);
        this.pageChanged.emit();
        this.skip = this.grid.wrapper.skip;
    }

    private resetForms(): void {
        this.grid.closeEditedRows(this.skip);
        this.rowEditUpdates = {};
        this.grid.rowEditFormGroups = null;
        this.grid.search();
    }

    buildGridOptions(): IpxGridOptions {
        const pageSizeSetting = this.localSettings.keys.caseView.designElement.pageSize;

        return {
            autobind: true,
            pageable: { pageSizeSetting, pageSizes: [5, 10, 20, 50] },
            navigable: true,
            sortable: true,
            reorderable: this.isHosted ? false : true,
            detailTemplateShowCondition: (dataItem: any): boolean => dataItem && dataItem.images && dataItem.images.length > 0,
            detailTemplate: this.detailTemplate,
            showExpandCollapse: true,
            showGridMessagesUsingInlineAlert: false,
            enableGridAdd: this.isHosted ? true : false,
            customRowClass: (context) => {
                if (context.dataItem && context.dataItem.error) {
                    return ' error';
                }

                return '';
            },
            read$: (queryParams) => {
                return this.service.getDesignElements(this.topic.params.viewData.caseKey, queryParams);
            },
            onDataBound: (data: any) => {
                if (data && data.total && this.topic.setCount) {
                    this.topic.setCount.emit(data.total);
                }
            },
            columns: this.getColumns(),
            columnSelection: {
                localSetting: this.localSettings.keys.caseView.relatedCases.columnsSelection
            },
            canAdd: true,
            rowMaintenance: this.canMaintainCase ? {
                canEdit: true,
                canDelete: true,
                rowEditKeyField: 'rowKey'
            } : null,
            maintainFormGroup$: this.maintainFormGroup$
        };
    }

    getChanges = (): { [key: string]: any; } => {
        const data = { designElement: { rows: [] } };
        const keys = Object.keys(this.grid.rowEditFormGroups);
        keys.forEach((r) => {
            const value = this.grid.rowEditFormGroups[r].value;
            data.designElement.rows.push(value);
        });

        return data;
    };

    getDataRows = (): Array<any> => {
        return Array.isArray(this.grid.wrapper.data) ? this.grid.wrapper.data : (this.grid.wrapper.data).data;
    };

    onError = (): void => {
        if (this.topic.setErrors) {
            this.topic.setErrors(true);
        }
    };

    onRowAddedOrEdited = (data: any): void => {
        const modal = this.modalService.openModal(DesignElementsMaintenanceComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                dataItem: data.dataItem,
                isAdding: data.dataItem.status === rowStatus.Adding,
                grid: this.grid,
                caseKey: this.topic.params.viewData.caseKey,
                rowIndex: data.rowIndex
            }
        });
        modal.content.onClose$.subscribe(
            (event: any) => {
                this.onCloseModal(event, data);
            }
        );
    };

    onCloseModal(event, data): void {
        if (event.success) {
            const rowObject = { rowIndex: data.rowIndex, dataItem: data.dataItem, formGroup: event.formGroup } as any;
            this.gridOptions.maintainFormGroup$.next(rowObject);
        }
        if (event.success) {
            this.updateChangeStatus();
        }

        if (this.isAnyRecordAddedWithPaging() && !this.service.isAddAnotherChecked.getValue()) {
            this.grid.closeEditedRows(this.skip);
            this.gridOptions._selectPage(1);
            this.updateChangeStatus();
        }

        if (event.success) {
            if (this.service.isAddAnotherChecked.getValue()) {
                this.gridOptions.maintainFormGroup$.next(null);
                this.grid.addRow();
            } else {
                this.modalService.modalRef.hide();
            }
        }
    }

    private readonly isAnyRecordAddedWithPaging = (): boolean => {
        let anyChanges = false;
        const dataRows = this.getDataRows();
        if (dataRows.some(x => x.status && x.status === rowStatus.Adding) && this.grid.wrapper.skip !== 0) {
            anyChanges = true;
        }

        return anyChanges;
    };

    private readonly refreshStatus = () => {
        const isValid = this.grid.isValid();
        let hasChanges = this.grid.isDirty();
        const dataRows = this.getDataRows();
        if (dataRows.some(x => x.status && x.status !== null)) {
            hasChanges = true;
        }
        this.caseDetailService.hasPendingChanges$.next(isValid && hasChanges);
        this.cdRef.detectChanges();
    };

    updateChangeStatus = (): void => {
        this.grid.checkChanges();
        const dataRows = this.getDataRows();
        this.topic.hasChanges = dataRows.some((r) => r.status);
        this.service.raisePendingChanges(this.topic.hasChanges);
        if (this.topic.getErrors) {
            this.service.raiseHasErrors(this.topic.getErrors());
        }
        this.refreshStatus();
    };

    setErrors = (errors: Array<ValidationError>): void => {
        if (errors) {
            errors.map((errs) => {
                const fg = this.grid.rowEditFormGroups[errs.id];
                if (fg) {
                    this.setDataRowErrors(true, errs.id);
                    this.notificationService.alert({ message: 'field.errors.duplicateDesignElement', continue: 'Ok' });
                    this.refreshStatus();
                }
            });
        }
    };

    setDataRowErrors = (isError: boolean, rowKey: number): void => {
        const dataRows = this.getDataRows();
        const dr = dataRows.filter(x => { return x.rowKey === rowKey; });
        if (dr) {
            dr[0].error = isError;
        }
    };

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: 'caseview.designElements.firmElementCaseRef',
            field: 'firmElementCaseRef'
        }, {
            title: 'caseview.designElements.clientElementCaseRef',
            field: 'clientElementCaseRef'
        }, {
            title: 'caseview.designElements.elementOfficialNo',
            field: 'elementOfficialNo'
        }, {
            title: 'caseview.designElements.registrationNo',
            field: 'registrationNo'
        }, {
            title: 'caseview.designElements.noOfViews',
            field: 'noOfViews'
        }, {
            title: 'caseview.designElements.elementDescription',
            field: 'elementDescription'
        }, {
            title: 'caseview.designElements.renew',
            field: 'renew',
            template: true,
            disabled: true,
            defaultColumnTemplate: DefaultColumnTemplateType.selection
        }, {
            title: 'caseview.designElements.stopRenewDate',
            field: 'stopRenewDate',
            template: true,
            type: 'date',
            defaultColumnTemplate: DefaultColumnTemplateType.date
        }];

        return columns;
    };

    byItem = (index: number, item: any): string => item;
}

export class CaseDesignElementsTopic extends Topic {
    readonly key = 'designElement';
    readonly title = caseViewTopicTitles.designElement;
    readonly component = DesignElementsComponent;
    readonly setCount = new EventEmitter<number>();
    constructor(public params: TopicParam) {
        super();
    }
}