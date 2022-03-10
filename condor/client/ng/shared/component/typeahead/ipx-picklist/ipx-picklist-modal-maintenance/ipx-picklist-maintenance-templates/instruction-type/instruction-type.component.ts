import { HttpClient } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { TypeDecorator } from 'shared/component/utility/type.decorator';
import { IpxPicklistMaintenanceService } from '../../../ipx-picklist-maintenance.service';
import { PicklistMainainanceComponent } from '../ipx-picklist-mainainance.component';

@TypeDecorator('IpxPicklistInstructionTypeComponent')
@Component({
    selector: 'ipx-picklist-instruction-type',
    templateUrl: './instruction-type.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxPicklistInstructionTypeComponent implements OnInit, PicklistMainainanceComponent {
    static componentName = 'IpxPicklistInstructionTypeComponent';
    form: FormGroup;
    @Input() set entry(value: InstructionType) {
        this._entry = value || {
            key: null,
            code: '',
            value: '',
            recordedAgainst: '',
            recordedAgainstId: '',
            restrictedBy: '',
            restrictedById: ''
        };
        this.isAdd = this._entry.code === '';
    }
    get entry(): InstructionType {
        return this.getEntry();
    }
    isAdd = false;
    nameTypes: Array<any>;
    private _entry: InstructionType;

    constructor(private readonly http: HttpClient, public service: IpxPicklistMaintenanceService) {
    }

    ngOnInit(): void {
        this.form = new FormGroup({
            code: new FormControl({ value: null, disabled: !this.isAdd }, [Validators.required, Validators.maxLength(3)]),
            value: new FormControl(null, [Validators.required]),
            recordedAgainst: new FormControl(null, []),
            restrictedBy: new FormControl(null, [])
        });
        this.loadNametypes();
    }

    private readonly getEntry = (): InstructionType => {
        if (this.form) {
            this._entry.code = this.form.controls.code.value;
            this._entry.value = this.form.controls.value.value;
            this._entry.recordedAgainstId = (this.form.controls.recordedAgainst.value) ? this.form.controls.recordedAgainst.value.key : '';
            this._entry.recordedAgainst = (this.form.controls.recordedAgainst.value) ? this.form.controls.recordedAgainst.value.value : '';
            this._entry.restrictedById = (this.form.controls.restrictedBy.value) ? this.form.controls.restrictedBy.value.key : '';
            this._entry.restrictedBy = (this.form.controls.restrictedBy.value) ? this.form.controls.restrictedBy.value.value : '';
        }

        return this._entry;
    };

    loadNametypes = () => {
        this.http.get('api/picklists/instructionTypes/nameTypes')
            .subscribe((values) => {
                this.nameTypes = values as Array<any>;
                const selectedRecordAgainst = this._entry.recordedAgainstId ? this.nameTypes.filter(v => v.key === this._entry.recordedAgainstId)[0] : { key: '', value: '' };
                const selectedRestrictedBy = this._entry.restrictedById ? this.nameTypes.filter(v => v.key === this._entry.restrictedById)[0] : { key: '', value: '' };

                this.form.setValue({
                    code: this._entry.code,
                    value: this._entry.value,
                    recordedAgainst: selectedRecordAgainst,
                    restrictedBy: selectedRestrictedBy
                });

                this.form.statusChanges.subscribe((value) => {
                    const state = this.service.modalStates$.getValue();
                    state.canSave = value === 'VALID';

                    this.service.nextModalState(state);
                });
            });
    };
}

export type InstructionType = {
    key: number,
    code: string,
    value: string,
    recordedAgainst: string,
    recordedAgainstId: string,
    restrictedBy: string,
    restrictedById: string
};
