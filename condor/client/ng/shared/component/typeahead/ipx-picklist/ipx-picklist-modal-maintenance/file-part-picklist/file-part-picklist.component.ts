import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { TypeDecorator } from 'shared/component/utility/type.decorator';
import * as _ from 'underscore';
import { IpxPicklistMaintenanceService } from '../../ipx-picklist-maintenance.service';
import { PicklistMainainanceComponent } from '../ipx-picklist-maintenance-templates/ipx-picklist-mainainance.component';
import { FilePart } from './file-part.model';

@TypeDecorator('FilePartPicklistComponent')
@Component({
    selector: 'file-part-picklist',
    templateUrl: './file-part-picklist.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class FilePartPicklistComponent implements OnInit, PicklistMainainanceComponent {
    static componentName = 'FilePartPicklistComponent';
    form: FormGroup;
    private _entry: FilePart;
    isUpdateAccess = false;
    @Input() set entry(value: FilePart) {
        this._entry = {
            key: null,
            value: '',
            caseId: 0
        };
        this._entry = _.extend(this._entry, value);
    }
    get entry(): FilePart {
        return this.getEntry();
    }

    constructor(public service: IpxPicklistMaintenanceService) {}

    ngOnInit(): void {
        this.form = new FormGroup({
            value: new FormControl(null, [Validators.required, Validators.maxLength(60), this.validateText])
        });
        this.isUpdateAccess = this.service.modalStates$.getValue().canAdd;
        this.loadData();
    }

    getEntry = (): any => {
        if (this.form) {
            this._entry.value = (this.form.controls.value.value) ? this.form.controls.value.value : '';
        }

        return this._entry;
    };

    validateText = (control: FormControl): any => {
        if (control && control.value) {
            if (control.value.trim().length === 0) {

                return {
                    required: 'true'
                };
            }

            return null;
        }
    };

    loadData = () => {
        this.form.setValue({
            value: this._entry.value
        });
        this.form.statusChanges.subscribe((value) => {
            const state = this.service.modalStates$.getValue();
            state.canSave = value === 'VALID' && this.form.dirty;
            if (state.canSave) {
                this.service.nextModalState(state);
            }
        });
    };
}