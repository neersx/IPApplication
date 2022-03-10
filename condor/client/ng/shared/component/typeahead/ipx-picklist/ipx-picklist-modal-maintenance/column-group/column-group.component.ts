import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { TypeDecorator } from 'shared/component/utility/type.decorator';
import * as _ from 'underscore';
import { IpxPicklistMaintenanceService } from '../../ipx-picklist-maintenance.service';
import { PicklistMainainanceComponent } from '../ipx-picklist-maintenance-templates/ipx-picklist-mainainance.component';

@TypeDecorator('IpxPicklistColumnGroupComponent')
@Component({
    selector: 'ipx-picklist-column-group',
    templateUrl: './column-group.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxPicklistColumnGroupComponent implements OnInit, PicklistMainainanceComponent {
    static componentName = 'IpxPicklistColumnGroupComponent';
    form: FormGroup;
    private _entry: ColumnGroup;
    isUpdateAccess = false;
    @Input() set entry(value: ColumnGroup) {
        this._entry = {
            key: null,
            value: '',
            contextId: 0
        };
        this._entry = _.extend(this._entry, value);
    }

    get entry(): ColumnGroup {
        return this.getEntry();
    }

    constructor(private readonly service: IpxPicklistMaintenanceService) { }

    ngOnInit(): void {
        this.form = new FormGroup({
            value: new FormControl(null, [Validators.required, Validators.maxLength(50)])
        });
        this.isUpdateAccess = this.service.modalStates$.getValue().canAdd;
        this.loadColumnGroupData();
    }

    private readonly getEntry = (): any => {
        if (this.form) {
            this._entry.value = (this.form.controls.value.value) ? this.form.controls.value.value : '';
        }

        return this._entry;
    };

    loadColumnGroupData = () => {
        this.form.setValue({
            value: this._entry.value
        });
        this.form.statusChanges.subscribe((value) => {
            const state = this.service.modalStates$.getValue();
            state.canSave = value === 'VALID' && this.form.dirty;
            this.service.nextModalState(state);
        });
    };
}

export class ColumnGroup {
    key?: number;
    value: string;
    contextId: number;
}