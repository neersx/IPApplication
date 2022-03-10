import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, ValidationErrors } from '@angular/forms';
import { DateHelper } from 'ajs-upgraded-providers/date-helper.provider';
import { LocalSettings } from 'core/local-settings';
import { TooltipDirective } from 'ngx-bootstrap/tooltip';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { IpxKendoGridComponent, rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { Topic } from 'shared/component/topics/ipx-topic.model';
import { TagsErrorValidator } from 'shared/component/typeahead/ipx-typeahead/typeahead.config.provider';
import * as _ from 'underscore';
import { TaxRateInlineState } from '../tax-code.model';
import { TaxCodeService } from '../tax-code.service';

@Component({
    selector: 'ipx-tax-code-rates',
    templateUrl: './tax-code-rates.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class TaxCodeRatesComponent implements OnInit {
    topic: Topic;
    taxRates: any = [];
    viewData: any;
    gridOptions: IpxGridOptions;
    sourceJurisdiction: string;
    isGridDirty = false;
    isGridValid = false;
    numericStyle = { maxWidth: '150px', marginLeft: '-10px' };
    errorStyle = { marginLeft: '-94px' };
    recordCount: number;
    @ViewChild('ipxKendoGridRef', { static: false }) grid: IpxKendoGridComponent;
    @ViewChild(TooltipDirective) tooltipDir: TooltipDirective;

    constructor(private readonly taxCodeService: TaxCodeService,
        readonly localSettings: LocalSettings, private readonly formBuilder: FormBuilder,
        private readonly cdRef: ChangeDetectorRef, readonly dateHelper: DateHelper) { }

    ngOnInit(): void {
        if (this.topic.params?.viewData) {
            this.viewData = { ...this.topic.params.viewData };
        }
        this.sourceJurisdiction = this.localSettings.keys.configuration.taxcodes.sourceJurisdiction.getLocal;
        this.gridOptions = this.buildGridOptions();
        Object.assign(this.topic, {
            getFormData: this.getFormData,
            isDirty: this.isDirty,
            isValid: this.isValid,
            clear: this.onClear,
            revert: this.revert
        });
    }

    getFormData = (): any => {
        if (this.isGridDirty) {
            this.updateChangeStatus();

            return { formData: { taxRatesDetails: this.getDataRows() } };
        }
    };

    isValid = (): boolean => {
        return this.grid.isValid() && this.isGridValid;
    };

    isDirty = (): boolean => {
        return this.isGridDirty;
    };

    revert = (): any => {
        this.isGridDirty = false;
        this.isGridValid = false;
    };
    onClear = () => {
        const dataRows = this.getDataRows();
        _.each(dataRows, (item: any, index: number) => {
            if (item) {
                this.grid.rowCancelHandler(null, index, item);
            }
        });
        this.grid.clear();
        this.gridOptions._search();
    };

    updateChangeStatus(): void {
        this.grid.checkChanges();
        const dataRows = this.getDataRows();
        this.topic.setCount.emit(dataRows.length);
        this.isGridDirty = true;
        this.applyValidation();
        this.isGridValid = !_.some(this.getDataRows(), (item: any) => {
            return item.duplicate === true;
        });
    }

    getDataRows = (): Array<any> => {
        return Array.isArray(this.grid.wrapper.data) ? this.grid.wrapper.data : (this.grid.wrapper.data).data;
    };

    change(dataItem: any): any {
        const rows = this.getDataRows();
        if (this.recordCount > 0) {
            this.recordCount = this.recordCount - 1;
            this.isGridValid = true;
        } else {
            const modified = _.first(rows.filter(x => x.id === dataItem.id && x.status !== TaxRateInlineState.Deleted && x.status !== TaxRateInlineState.Added));
            if (modified) {
                modified.status = TaxRateInlineState.Modified;
            }
            this.updateChangeStatus();
        }
    }

    applyValidation(): void {
        const dataRows = this.getDataRows().filter(x => x.status !== TaxRateInlineState.Deleted);
        const dataRowsForAll = dataRows.filter(item => item.sourceJurisdiction && item.taxRate && item.effectiveDate);
        if (dataRowsForAll.length > 0) {
            const groupData = _.groupBy(dataRowsForAll, (item: any) => {
                return [item.sourceJurisdiction, item.taxRate, this.dateHelper.toLocal(item.effectiveDate)].sort();
            });
            _.each(groupData, (item: any) => {
                if (item.length > 1) {
                    this.markAsDuplicate(item, true);
                } else {
                    this.markAsDuplicate(item, false);
                }
            });
        }

        const dataRowsForRateAndDate = dataRows.filter(item => (item.sourceJurisdiction === null || item.sourceJurisdiction.code === '') && item.taxRate && item.effectiveDate);
        if (dataRowsForRateAndDate.length > 0) {
            const groupData = _.groupBy(dataRowsForRateAndDate, (item: any) => {
                return [item.taxRate, this.dateHelper.toLocal(item.effectiveDate)].sort();
            });
            _.each(groupData, (item: any) => {
                if (item.length > 1) {
                    this.markAsDuplicate(item, true);
                } else {
                    this.markAsDuplicate(item, false);
                }
            });
        }
        const deletedRows = this.getDataRows().filter(x => x.status === TaxRateInlineState.Deleted);
        if (deletedRows.length > 0) {
            this.markAsDuplicate(deletedRows, false);
        }
    }

    markAsDuplicate(dataRows: any, isDuplicate: boolean): void {
        _.each(dataRows, (item: any) => {
            item.duplicate = isDuplicate;
        });
    }

    private buildGridOptions(): IpxGridOptions {
        const options: IpxGridOptions = {
            canAdd: this.viewData.taskSecurity.canCreateTaxCode,
            enableGridAdd: this.viewData.taskSecurity.canCreateTaxCode,
            onDataBound: (data: any) => {
                if (data && data.length && this.topic.setCount) {
                    this.topic.setCount.emit(data.length);
                    this.recordCount = data.length;
                } else {
                    this.recordCount = 0;
                }
                _.each(data, (item: any) => {
                    item.showEditAttributes = { display: false };
                    item.showDeleteAttributes = { display: true };
                });
                this.isGridValid = true;
            },
            read$: () => {
                return this.taxCodeService.taxRatesDetails(this.viewData.taxRateId);
            },
            columns: [{
                field: 'sourceJurisdiction', title: 'taxCode.rates.sourceJurisdiction', width: 400, template: true, sortable: false
            }, {
                field: 'taxRate', title: 'taxCode.rates.taxRate', template: true, sortable: false, width: 200
            }, {
                field: 'effectiveDate', title: 'taxCode.rates.effectiveDate', template: true, sortable: false, width: 200
            }],
            selectedRecords: {
                rows: {
                    rowKeyField: 'id',
                    selectedKeys: []
                }
            }
        };
        Object.assign(options, {
            rowMaintenance: {
                canEdit: this.viewData.taskSecurity.canUpdateTaxCode,
                inline: this.viewData.taskSecurity.canUpdateTaxCode,
                rowEditKeyField: 'id',
                width: 50,
                canDelete: true
            },

            // tslint:disable-next-line: unnecessary-bind
            createFormGroup: this.createFormGroup.bind(this)
        });

        return options;
    }

    createFormGroup = (dataItem: any): FormGroup => {
        const formGroup = this.formBuilder.group({
            taxRateId: dataItem.id,
            sourceJurisdiction: new FormControl(undefined, this.duplicateNameType),
            taxRate: new FormControl(),
            effectiveDate: new FormControl()
        });
        formGroup.markAsPristine();

        this.gridOptions.formGroup = formGroup;
        if (dataItem.status === TaxRateInlineState.Added) {
            dataItem.showEditAttributes = { display: false };
        }

        return formGroup;
    };

    private readonly duplicateNameType = (c: AbstractControl): ValidationErrors | null => {
        this.cdRef.markForCheck();
        if (c.value && c.dirty) {
            const newIds = [].concat(...c.value).map(m => m.code).join(',');
            const dataRows = this.grid.getCurrentData().filter(d => d.status !== rowStatus.editing).map(d => [].concat(...d.sourceJurisdiction));
            const dataRowsIds = dataRows.map(d => d.map(e => e.code)).map(d => d.join(',')).filter(x => x !== '');

            const fgs = this.grid.rowEditFormGroups;
            const fgDataRow = Object.keys(fgs || {})
                .filter(f => fgs[f].value)
                .map(f => [].concat(...fgs[f].value.sourceJurisdiction));
            const fgDataRowIds = fgDataRow.map(d => d.map(e => e.code)).map(d => d.join(','));

            const allIds = dataRowsIds.concat(fgDataRowIds.filter(x => x !== ''));
            const counts = allIds.join(',').split(',').reduce((map, val) => {
                map[val] = (map[val] ? map[val] : 0) + 1;

                return map;
            }, {});
            const duplicates = [];
            newIds.split(',').forEach(x => {
                if (counts[x] > 1) {
                    duplicates.push(x);
                }
            });

            if (duplicates.length > 0) {
                const errorObj: TagsErrorValidator = {
                    validator: { duplicate: 'duplicate' },
                    keys: duplicates,
                    keysType: 'code',
                    applyOnChange: true
                };

                return { duplicate: 'duplicate', errorObj };
            }

        }
    };
}