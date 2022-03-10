import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { FormControl, FormGroup, Validators } from '@angular/forms';
import { TypeDecorator } from 'shared/component/utility/type.decorator';
import * as _ from 'underscore';
import { IpxPicklistMaintenanceService } from '../../ipx-picklist-maintenance.service';
import { PicklistMainainanceComponent } from '../ipx-picklist-maintenance-templates/ipx-picklist-mainainance.component';

@TypeDecorator('TaskPlannerPicklistComponent')
@Component({
    selector: 'task-planner-picklist',
    templateUrl: './task-planner-picklist.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class TaskPlannerPicklistComponent implements OnInit, PicklistMainainanceComponent {
    static componentName = 'DataItemPicklistComponent';
    form: FormGroup;
    errorStatus: Boolean;
    maintainPublicSearch = false;
    canUpdateSavedSearch = false;
    private _entry: TaskPlannerMaintenance;
    @Input() set entry(valueRecieve: TaskPlannerMaintenance) {
        this._entry = {
            key: null,
            searchName: null,
            description: null,
            isPublic: null,
            presentationId: null,
            value: null,
            maintainPublicSearch: null,
            canUpdateSavedSearch: null
        };
        if (valueRecieve) {
            this._entry.key = valueRecieve.key;
        }
        this._entry = _.extend(this._entry, valueRecieve);
    }

    get entry(): TaskPlannerMaintenance {
        return this.getEntry();
    }

    constructor(private readonly service: IpxPicklistMaintenanceService) {
        this.checkForPublicSearch = this.checkForPublicSearch.bind(this);
    }

    ngOnInit(): void {
        this.errorStatus = false;
        this.form = new FormGroup({
            value: new FormControl(null, [Validators.required]),
            description: new FormControl(null),
            isPublic: new FormControl(false)
        });
        this.loadData();
    }

    loadData = () => {
        this.form.setValue({
            value: this._entry.searchName,
            description: this._entry.description,
            isPublic: this._entry.isPublic
        });
        this.maintainPublicSearch = this._entry.maintainPublicSearch;
        this.canUpdateSavedSearch = this._entry.canUpdateSavedSearch;
        this.form.statusChanges.subscribe((value) => {
            const state = this.service.modalStates$.getValue();
            state.canSave = value === 'VALID' && this.form.dirty;
            state.canSave = this.checkForPublicSearch();
            this.service.nextModalState(state);
        });
    };

    checkForPublicSearch(): boolean {
        return !(this._entry.isPublic ? !(this._entry.maintainPublicSearch && this.canUpdateSavedSearch) : !this.canUpdateSavedSearch);
    }

    readonly getEntry = (): TaskPlannerMaintenance => {
        if (this.form) {
            this._entry.searchName = this.form.controls.value.value ? this.form.controls.value.value : '';
            this._entry.value = this.form.controls.value.value ? this.form.controls.value.value : '';
            this._entry.description = this.form.controls.description.value ? this.form.controls.description.value : '';
            this._entry.isPublic =  this.form.controls.isPublic.value ? true : false;
        }

        return this._entry;
    };

}

export class TaskPlannerMaintenance {
    key?: number;
    value?: string;
    searchName?: string;
    description?: string;
    isPublic?: boolean;
    presentationId?: number;
    maintainPublicSearch?: boolean;
    canUpdateSavedSearch?: boolean;
}