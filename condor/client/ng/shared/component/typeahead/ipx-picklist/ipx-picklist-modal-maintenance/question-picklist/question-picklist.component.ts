import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit } from '@angular/core';
import { FormControl, FormGroup, ValidationErrors, Validators } from '@angular/forms';
import { TranslateService } from '@ngx-translate/core';
import { BehaviorSubject, Subject } from 'rxjs';
import { TypeDecorator } from 'shared/component/utility/type.decorator';
import * as _ from 'underscore';
import { IpxPicklistMaintenanceService } from '../../ipx-picklist-maintenance.service';
import { PicklistMainainanceComponent } from '../ipx-picklist-maintenance-templates/ipx-picklist-mainainance.component';
import { IpxQuestionPicklistService } from './question-picklist.service';

@TypeDecorator('QuestionPicklistComponent')
@Component({
    selector: 'ipx-question-picklist',
    templateUrl: './question-picklist.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class QuestionPicklistComponent implements OnInit, PicklistMainainanceComponent {
    form: FormGroup;
    state: any;
    key?: number;
    generalResponseOptions: Array<any>;
    yesNoResponseOptions: Array<any>;
    periodResponseOptions: Array<any>;
    tableTypes: Array<any>;
    isPeriodDisabled: boolean;
    private _entry: any;

    get entry(): any {
        return this.getEntry();
    }
    @Input() set entry(valueReceived: any) {
        this._entry = {
            key: null,
            code: null,
            question: null,
            instructions: null,
            yesNo: null,
            count: null,
            amount: null,
            staff: null,
            text: null,
            period: null,
            list: null
        };
        if (valueReceived) {
            this._entry.code = valueReceived.code;
            this._entry.question = valueReceived.question;
            this._entry.instructions = valueReceived.instructions;
            this._entry.yesNo = valueReceived.yesNo;
            this._entry.count = valueReceived.count;
            this._entry.amount = valueReceived.amount;
            this._entry.staff = valueReceived.staff;
            this._entry.text = valueReceived.text;
            this._entry.period = valueReceived.period;
            this._entry.listType = valueReceived.listType;
        }
        this._entry = _.extend(this._entry, valueReceived);
    }

    constructor(public service: IpxPicklistMaintenanceService,  private readonly cdRef: ChangeDetectorRef, private readonly questionPicklistService: IpxQuestionPicklistService, readonly translate: TranslateService) {
        this.questionPicklistService.getViewData();
        this.generalResponseOptions = [
            { value: 0, label: this.translate.instant('picklist.question.types.hide') },
            { value: 1, label: this.translate.instant('picklist.question.types.mandatory') },
            { value: 2, label: this.translate.instant('picklist.question.types.optional') }
        ];
        this.yesNoResponseOptions = [...this.generalResponseOptions, { value: 4, label: 'picklist.question.types.defaultToYes' }, { value: 5, label: 'picklist.question.types.defaultToNo' }];
    }

    ngOnInit(): void {
        this.isPeriodDisabled = false;
        this.state = this.service.maintenanceMetaData$.getValue();
        this.form = new FormGroup({
            code: new FormControl(null),
            question: new FormControl(null),
            instructions: new FormControl(null),
            yesNo: new FormControl(null),
            count: new FormControl(null),
            amount: new FormControl(null),
            staff: new FormControl(null),
            text: new FormControl(null),
            period: new FormControl(null),
            list: new FormControl(null)
        }, { validators: [this._eitherCodeOrQuestionEntered]});
        this.loadData();
    }

    loadData = () => {
        this.questionPicklistService.viewData$
            .subscribe((values: any) => {
                this.periodResponseOptions = [...this.generalResponseOptions,
                    { value: 4, label: values.periodTypes[_.findIndex(values.periodTypes, (i: any) => { return i.userCode === 'D'; })].periodType },
                    { value: 5, label: values.periodTypes[_.findIndex(values.periodTypes, (i: any) => { return i.userCode === 'M'; })].periodType },
                    { value: 6, label: values.periodTypes[_.findIndex(values.periodTypes, (i: any) => { return i.userCode === 'Y'; })].periodType }
                ];
                this.tableTypes = values.tableTypes;
                this.form.controls.list.setValue(this._entry.listType);
                this.cdRef.detectChanges();
            });

        this.form.setValue({
            code: this._entry.code ?? null,
            question: this._entry.question ?? null,
            instructions: this._entry.instructions ?? null,
            yesNo: this._entry.yesNo ?? null,
            count: this._entry.count ?? null,
            amount: this._entry.amount ?? null,
            staff: this._entry.staff ?? null,
            text: this._entry.text ?? null,
            period: this._entry.period ?? null,
            list: this._entry.listType ?? null
        });
        this.key = this._entry.key;
        this.form.statusChanges.subscribe((value) => {
            const state = this.service.modalStates$.getValue();
            state.canSave = value === 'VALID' && this.form.dirty;
            if (state.canSave) {
                this.service.nextModalState(state);
            }
        });
        this.togglePeriod();
    };

    togglePeriod = (): void => {
        if (this.form.controls.count.value !== 1 && this.form.controls.count.value !== 2) {
            this.isPeriodDisabled = true;
            this.form.controls.period.setValue(null);
        } else {
            this.isPeriodDisabled = false;
        }

        this.cdRef.detectChanges();
    };

    private readonly _eitherCodeOrQuestionEntered = (c: FormGroup): ValidationErrors | null => {
        if ((c.controls.code.value === null || c.controls.code.value === '') && (c.controls.question.value === null || c.controls.question.value === '')) {
            c.controls.code.setErrors({ 'question.eitherCodeOrQuestion': true });
            c.controls.question.setErrors({ 'question.eitherCodeOrQuestion': true });

            return { errorMessage: 'question.eitherCodeOrQuestion' };
        }
        if (!c.controls.code.hasError('maxlength')) {
            c.controls.code.setErrors(null);
        }
        if (!c.controls.question.hasError('maxlength')) {
            c.controls.question.setErrors(null);
        }
        if (!c.controls.instructions.hasError('maxlength')) {
            c.controls.instructions.setErrors(null);
        }

        return null;
    };

    readonly getEntry = (): any => {
        if (this.form) {
            this._entry.code = this.form.controls.code.value;
            this._entry.question = this.form.controls.question.value;
            this._entry.instructions = this._entry.instructions = this.form.controls.instructions.value;
            this._entry.yesNo = this.form.controls.yesNo.value;
            this._entry.count = this.form.controls.count.value;
            this._entry.amount = this.form.controls.amount.value;
            this._entry.staff = this.form.controls.staff.value;
            this._entry.text = this.form.controls.text.value;
            this._entry.period = this.form.controls.period.value;
            this._entry.listType = this.form.controls.list.value;
            this._entry.key = this.key;
            this._entry.value = this._entry.question || this._entry.code;
        }

        return this._entry;
    };
}
