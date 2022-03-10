import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnChanges, OnDestroy, OnInit, Output, SimpleChanges, TemplateRef, ViewChild } from '@angular/core';
import { of, Subscription } from 'rxjs';
import { distinctUntilChanged, tap } from 'rxjs/operators';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import * as _ from 'underscore';
import { RecordalStepElement } from '../affected-cases.model';
import { AffectedCasesService } from '../affected-cases.service';

@Component({
    selector: 'ipx-recordal-step-elements',
    templateUrl: './recordal-step-elements.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class RecordalStepElementComponent implements OnInit, OnDestroy, OnChanges {

    gridOptions: IpxGridOptions;
    @Input() canMaintain: boolean;
    @Input() caseKey: number;
    @Input() stepId: number;
    @Input() isHosted: boolean;
    @Input() recordalType: number;
    @Input() isAssignedStep: boolean;
    @ViewChild('detailTemplate', { static: true }) detailTemplate: TemplateRef<any>;
    @ViewChild('stepElementsGrid', { static: false }) grid: IpxKendoGridComponent;
    @Output() readonly disableSave = new EventEmitter();

    subscription: Subscription;
    currentAddressSubscription: Subscription;
    stepElements: Array<RecordalStepElement>;

    constructor(private readonly service: AffectedCasesService,
        private readonly cdref: ChangeDetectorRef) { }

    ngOnInit(): void {
        this.subscription = this.service.rowSelected$.pipe(
            distinctUntilChanged(),
            tap((step) => {
                this.stepId = step.stepId;
                this.stepElements = step.recordalStepElement;
                this.recordalType = step.recordalType;
            })
        ).subscribe(() => {
            this.gridOptions = this.buildGridOptions();
            this.cdref.markForCheck();
        });
        this.currentAddressSubscription = this.service.currentAddressChange$.subscribe(stepElement => {
            if (stepElement) {
                const data = this.getDataRows();
                data.forEach(step => {
                    if (step.elementId === stepElement.elementId) {
                        step.namePicklist = stepElement.namePicklist;
                        step.addressPicklist = stepElement.addressPicklist;
                        const index = this.getRowIndexForStep(step.elementId);
                        this.grid.wrapper.collapseRow(index);
                        this.cdref.markForCheck();
                    }
                });
            } else {
                this.disableSave.emit(true);
            }
        });
    }

    ngOnChanges(changes: SimpleChanges): void {
        if (changes.stepId && this.gridOptions) {
            this.getDataRows().forEach((d, index) => {
                const idx = this.grid.wrapper.skip !== 0 ? (index - this.grid.wrapper.skip) : index;
                this.grid.wrapper.collapseRow(idx);
            });
            this.cdref.markForCheck();
        }
    }

    ngOnDestroy(): void {
        if (!!this.subscription) {
            this.subscription.unsubscribe();
        }
        if (!!this.currentAddressSubscription) {
            this.currentAddressSubscription.unsubscribe();
        }
    }

    getDataRows = (): Array<any> => {
        return Array.isArray(this.grid.wrapper.data) ? this.grid.wrapper.data : (this.grid.wrapper.data).data;
    };

    getRowIndexForStep(elementId: number): number {
        return _.findIndex(this.getDataRows(), { elementId });
    }

    buildGridOptions(): IpxGridOptions {

        return {
            autobind: true,
            navigable: true,
            pageable: false,
            reorderable: false,
            sortable: false,
            filterable: false,
            read$: () => {
                if (this.stepElements && this.stepElements.length > 0) {
                    return of(this.stepElements);
                }

                return this.service.getRecordalStepElements(this.caseKey, this.stepId, this.recordalType);
            },
            detailTemplate: this.detailTemplate,
            columns: this.getColumns(),
            rowMaintenance: {
                rowEditKeyField: 'elementId'
            },
            onDataBound: (data: any) => {
                if (data) {
                    this.service.originalStepElements = data;
                }
            }
        };
    }

    private readonly getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [
            {
                title: 'caseview.recordal.element',
                field: 'element',
                sortable: false,
                width: 180
            }, {
                title: 'caseview.recordal.label',
                field: 'label',
                sortable: false,
                width: 180
            }, {
                title: 'caseview.recordal.value',
                field: 'value',
                sortable: false
            }, {
                title: 'caseview.recordal.otherValue',
                field: 'otherValue',
                sortable: false
            }];

        return columns;
    };
}