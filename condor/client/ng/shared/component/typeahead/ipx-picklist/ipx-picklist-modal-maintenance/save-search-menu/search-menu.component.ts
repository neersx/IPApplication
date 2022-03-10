import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { TypeDecorator } from 'shared/component/utility/type.decorator';
import * as _ from 'underscore';
import { IpxPicklistMaintenanceService } from '../../ipx-picklist-maintenance.service';
import { PicklistMainainanceComponent } from '../ipx-picklist-maintenance-templates/ipx-picklist-mainainance.component';

@TypeDecorator('IpxPicklistSaveSearchMenuComponent')
@Component({
    selector: 'ipx-picklist-search-menu',
    templateUrl: './search-menu.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class IpxPicklistSaveSearchMenuComponent implements OnInit, PicklistMainainanceComponent {
    static componentName = 'IpxPicklistSaveSearchMenuComponent';
    form: FormGroup;
    private _entry: SearchMenuGroup;
    isUpdateAccess = false;
    @Input() set entry(value: SearchMenuGroup) {
        this._entry = {
            key: null,
            value: '',
            groupName: '',
            contextId: 0
        };
        this._entry = _.extend(this._entry, value);
    }
    get entry(): SearchMenuGroup {
        return this.getEntry();
    }

    constructor(public service: IpxPicklistMaintenanceService) {
    }

    ngOnInit(): void {
        this.form = new FormGroup({
            value: new FormControl(null, [Validators.required, Validators.maxLength(50)])
        });
        this.isUpdateAccess = this.service.modalStates$.getValue().canAdd;
        this.loadSearchGroupData();
    }

    private readonly getEntry = (): any => {
        if (this.form) {
            this._entry.value = (this.form.controls.value.value) ? this.form.controls.value.value : '';
            this._entry.groupName = this._entry.value;
        }

        return this._entry;
    };

    loadSearchGroupData = () => {
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

export class SearchMenuGroup {
    key?: number;
    value: string;
    contextId: number;
    groupName: string;
}