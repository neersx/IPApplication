import { ChangeDetectionStrategy, Component, Input, OnInit, ViewChild } from '@angular/core';
import { NgForm } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { StateService } from '@uirouter/angular';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { BehaviorSubject } from 'rxjs';
import { IpxBulkActionOptions } from 'shared/component/grid/bulkactions/ipx-bulk-actions-options';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxModalService } from 'shared/component/modal/modal.service';
import * as _ from 'underscore';
import { TaxCodeMaintenanceComponent } from './tax-code-maintenance.component';
import { TaxCodeCriteria, TaxCodeState } from './tax-code.model';
import { TaxCodeService } from './tax-code.service';

@Component({
    selector: 'tax-code',
    templateUrl: './tax-code-component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class TaxCodeComponent implements OnInit {
    @Input() viewData: any;
    gridOptions: IpxGridOptions;
    bsModalRef: BsModalRef;
    searchCriteria = new TaxCodeCriteria();
    searchText: string;
    actions: Array<IpxBulkActionOptions>;
    isTaxCodesLoaded = new BehaviorSubject<boolean>(false);
    callOnsaveTaxCodes = false;
    taxCodeState = TaxCodeState;
    @ViewChild('taxCodeForm', { static: true }) taxCodeForm: NgForm;
    @ViewChild('taxCodeGrid', { static: true }) taxCodeGrid: IpxKendoGridComponent;
    _resultsGrid: IpxKendoGridComponent;
    @ViewChild('taxCodeGrid') set resultsGrid(grid: IpxKendoGridComponent) {
        if (grid && !(this._resultsGrid === grid)) {
            if (this._resultsGrid) {
                this._resultsGrid.rowSelectionChanged.unsubscribe();
            }
            this._resultsGrid = grid;
            this.subscribeRowSelectionChange();
        }
    }

    constructor(private readonly taxCodeService: TaxCodeService, private readonly translate: TranslateService,
        private readonly modalService: IpxModalService, private readonly notificationService: NotificationService,
        private readonly stateService: StateService) { }

    ngOnInit(): void {
        this.taxCodeService.inUseTaxCode = [];
        const previousState = this.taxCodeService._previousStateParam$.getValue();
        if (previousState) {
            this.searchCriteria.text = previousState.formData;
        }
        this.actions = this.initializeMenuActions();
        this.gridOptions = this.buildGridOptions();
    }

    private buildGridOptions(): IpxGridOptions {
        this.taxCodeGrid.rowSelectionChanged.subscribe((event) => {
            const anySelected = event.rowSelection.length > 0;
            this.anySelectedSubject.next(anySelected);
        });

        return {
            sortable: true,
            selectable: {
                mode: 'multiple'
            },
            onDataBound: (data: any) => {
                this.taxCodeGrid.resetSelection();
                this.taxCodeService.markInUse(data);
                if (this.callOnsaveTaxCodes) {
                    this.callOnsaveTaxCodes = false;
                    this.isTaxCodesLoaded.next(true);
                }
            },
            customRowClass: (context) => {
                if (context.dataItem.inUse) {
                    return ' error';
                }

                return '';
            },
            bulkActions: this.actions,
            read$: (queryParams) => {
                return this.taxCodeService.getTaxCodes(this.searchCriteria, queryParams);
            },
            columns: [{
                field: 'taxCode', title: 'taxCode.code', width: 250, template: true, sortable: true
            }, {
                field: 'description', title: 'taxCode.description', template: true, sortable: true
            }],
            selectedRecords: {
                rows: {
                    rowKeyField: 'id',
                    selectedKeys: []
                }
            }
        };
    }

    search = (value: any): void => {
        this.searchCriteria.text = value?.value;
        this.gridOptions._search();
    };

    clear(): void {
        this.searchCriteria.text = '';
        this.gridOptions._search();
    }

    openModal = (dataItem: any, state: string) => {
        const initialState = {
            displayNavigation: state === 'updating' ? true : false,
            states: state,
            dataItem
        };
        this.bsModalRef = this.modalService.openModal(TaxCodeMaintenanceComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState
        });
        this.bsModalRef.content.searchRecord.subscribe(
            (callbackParams: any) => {
                this.bsModalRef.hide();
                if (callbackParams.taxRateId) {
                    this.taxCodeService.inUseTaxCode = [];
                    this.callOnsaveTaxCodes = true;
                    this.isTaxCodesLoaded.subscribe(result => {
                        if (result) {
                            let item = this.dataItemByTaxCode(callbackParams.taxRateId);
                            if (!item) {
                                item = { id: callbackParams.taxRateId, rowKey: -1 };
                            }
                            this.openTaxDetails(item);
                        }
                    });
                    const value = { value: this.searchCriteria.text };
                    this.search(value);
                }
            }
        );
    };

    dataItemByTaxCode(taxRateId: number): any {
        const data: any = this._resultsGrid.wrapper.data;
        const dataItem = _.first(data.filter(d => d.id === taxRateId));

        return dataItem;
    }

    openTaxDetails = (dataItem: any): void => {
        if (!dataItem.id) { return; }
        this.taxCodeService._previousStateParam$.next({ formData: this.searchCriteria.text });
        this.stateService.go('tax-details', {
            id: dataItem.id,
            rowKey: dataItem.rowKey
        }, { inherit: false });
    };

    anySelectedSubject = new BehaviorSubject<boolean>(false);
    private initializeMenuActions(): Array<IpxBulkActionOptions> {
        const menuItems: Array<IpxBulkActionOptions> = [{
            ...new IpxBulkActionOptions(),
            id: 'deleteAll',
            icon: 'cpa-icon cpa-icon-trash',
            text: 'roleSearch.delete',
            enabled: false,
            click: () => {
                this.notificationService.confirmDelete({
                    message: 'modal.confirmDelete.message'
                }).then(() => {
                    this.deleteSelectedTaxCodes();
                });
            }
        }];

        return menuItems;
    }
    resetSelection = () => {
        this.taxCodeService.inUseTaxCode = [];
        this.taxCodeGrid.resetSelection();
    };
    deleteSelectedTaxCodes = () => {
        const selections = this.taxCodeGrid.getSelectedItems('id');
        this.taxCodeService.deleteTaxCodes(selections).subscribe((response: any) => {
            this.resetSelection();
            if (response.hasError) {
                const allInUse = selections.length === response.inUseIds.length;
                const message = allInUse ? this.translate.instant('roleDetails.alert.alreadyInUse')
                    : this.translate.instant('modal.alert.partialComplete') + '<br/>' + this.translate.instant('roleDetails.alert.alreadyInUse');
                const title = allInUse ? 'modal.unableToComplete' : 'modal.partialComplete';
                this.taxCodeService.inUseTaxCode = this.taxCodeService.inUseTaxCode
                    .concat(response.inUseIds);
                this.notificationService.alert({
                    title,
                    message
                });
                this.gridOptions._search();
            } else {
                this.notificationService.success();
                this.gridOptions._search();
            }
        });
    };
    subscribeRowSelectionChange = () => {
        this._resultsGrid.rowSelectionChanged.subscribe((event) => {
            const anySelected = event.rowSelection.length > 0;
            const deleteAll = this.actions.find(x => x.id === 'deleteAll');
            if (deleteAll) {
                deleteAll.enabled = anySelected && this.viewData.canDeleteTaxCode;
            }
        });
    };
}