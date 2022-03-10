import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { KnownNameTypes } from 'names/knownnametypes';
import { NameFilteredPicklistScope } from 'search/case/case-search-topics/name-filtered-picklist-scope';
import * as _ from 'underscore';
import { AffectedCasesFilterModel, FilterValue } from '../model/filter.model';

@Component({
    selector: 'ipx-affcase-filter-menu',
    templateUrl: './filter-menu.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class AffectedCasesFilterMenuComponent implements OnInit {
    formGroup: any;
    @Input() filterParams: any;
    @Input() caseKey: any;
    @Output() readonly onFilterSelect = new EventEmitter();

    ownerPickListExternalScope: NameFilteredPicklistScope;

    constructor(
        private readonly knownNameTypes: KnownNameTypes,
        private readonly translate: TranslateService) {
    }

    ngOnInit(): void {
        this.ownerPickListExternalScope = new NameFilteredPicklistScope(
            this.knownNameTypes.Owner,
            this.translate.instant('picklist.owner'),
            false
        );

        this.createFormGroup();
        if (this.filterParams) {
            this.loadExistingFilter(this.filterParams.value);
        }
    }

    createFormGroup = (): FormGroup => {
        this.formGroup = new FormGroup({
            stepNumber: new FormControl(),
            recordalType: new FormControl(),
            caseRef: new FormControl(),
            jurisdiction: new FormControl(),
            propertyType: new FormControl(),
            officialNo: new FormControl(),
            currentOwner: new FormControl(),
            foreignAgent: new FormControl(),
            pending: new FormControl(false),
            registered: new FormControl(false),
            dead: new FormControl(false),
            notYetFiled: new FormControl(false),
            filed: new FormControl(false),
            recorded: new FormControl(false),
            rejected: new FormControl(false)
        });

        return this.formGroup;
    };

    loadExistingFilter(filter): any {
        if (filter && !_.values(filter).some(x => x)) { return; }

        this.formGroup.patchValue({
            stepNumber: filter.stepNumber,
            recordalType: filter.recordalType,
            caseRef: filter.caseRef,
            jurisdiction: filter.jurisdiction,
            propertyType: filter.propertyType,
            officialNo: filter.officialNo,
            currentOwner: filter.currentOwner,
            foreignAgent: filter.foreignAgent,
            pending: filter.pending,
            registered: filter.registered,
            dead: filter.dead,
            notYetFiled: filter.notYetFiled,
            filed: filter.filed,
            recorded: filter.recorded,
            rejected: filter.rejected
        });
    }

    get recordalType(): AbstractControl {
        return this.formGroup.get('recordalType');
    }

    get jurisdiction(): AbstractControl {
        return this.formGroup.get('jurisdiction');
    }

    get propertyType(): AbstractControl {
        return this.formGroup.get('propertyType');
    }

    get currentOwner(): AbstractControl {
        return this.formGroup.get('currentOwner');
    }

    get foreignAgent(): AbstractControl {
        return this.formGroup.get('foreignAgent');
    }

    clear = (): void => {
        this.createFormGroup();
        const obj = { filter: null, form: null };
        this.onFilterSelect.emit(obj);
    };

    submit = (): void => {
        if (this.formGroup.dirty) {
            const filter = this.prepareFilter();
            const obj = { filter, form: this.formGroup };
            this.onFilterSelect.emit(obj);
        }
    };

    prepareFilter = (): AffectedCasesFilterModel => {
        const result = new AffectedCasesFilterModel();
        result.filters = new Array<FilterValue>();

        result.filters.push({ field: 'agentId', value: this.formGroup.controls.foreignAgent.value ? this.formGroup.controls.foreignAgent.value.key : null });
        result.filters.push({ field: 'propertyType', value: this.formGroup.controls.propertyType.value ? this.formGroup.controls.propertyType.value.value : null });
        result.filters.forEach(x => { x.operator = 'in'; x.type = 'string'; });
        result.filters.push({ field: 'officialNo', value: this.formGroup.controls.officialNo.value, operator: 'contains', type: 'string' });
        const effectiveFilters = result.filters.filter(x => x.value !== null);
        result.filters = effectiveFilters;
        result.stepNo = this.formGroup.controls.stepNumber.value ? this.getStepNo(this.formGroup.controls.stepNumber.value) : null;
        result.caseStatus = this.selectedCaseStatus();
        result.jurisdictions = this.formGroup.controls.jurisdiction.value ? this.formGroup.controls.jurisdiction.value.map(x => x.key) : null;
        result.recordalStatus = this.selectedRecordalStatus();
        result.caseReference = this.formGroup.controls.caseRef.value ? this.formGroup.controls.caseRef.value : null;
        result.recordalTypeNo = this.formGroup.controls.recordalType.value ? this.formGroup.controls.recordalType.value.key : null;
        result.ownerId = this.formGroup.controls.currentOwner.value ? this.formGroup.controls.currentOwner.value.key : null;

        return result;
    };

    private readonly getStepNo = (step: string): number => {
        if (!step) { return null; }
        const r = /\d+/;
        const stepNo = step.match(r);

        return +stepNo;
    };

    private readonly selectedCaseStatus = (): any => {
        const status = [];
        if (this.formGroup.controls.pending.value) {
            status.push(CaseStatus.pending());
        }
        if (this.formGroup.controls.registered.value) {
            status.push(CaseStatus.registered());
        }
        if (this.formGroup.controls.dead.value) {
            status.push(CaseStatus.dead());
        }

        return status;
    };

    private readonly selectedRecordalStatus = (): any => {
        const status = [];
        if (this.formGroup.controls.notYetFiled.value) {
            status.push(RecordalStatus.notYetFiled());
        }
        if (this.formGroup.controls.filed.value) {
            status.push(RecordalStatus.filed());
        }
        if (this.formGroup.controls.recorded.value) {
            status.push(RecordalStatus.recorded());
        }
        if (this.formGroup.controls.rejected.value) {
            status.push(RecordalStatus.rejected());
        }

        return status;
    };
}

export class CaseStatus {
    static pending = (): string => {
        return 'Pending';
    };
    static registered = (): string => {
        return 'Registered';
    };
    static dead = (): string => {
        return 'Dead';
    };
}

export class RecordalStatus {
    static notYetFiled = (): string => {
        return 'Not Yet Filed';
    };
    static filed = (): string => {
        return 'Filed';
    };
    static recorded = (): string => {
        return 'Recorded';
    };
    static rejected = (): string => {
        return 'Rejected';
    };
}