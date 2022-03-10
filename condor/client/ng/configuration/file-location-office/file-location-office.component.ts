import { ChangeDetectionStrategy, Component, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormGroup } from '@angular/forms';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BehaviorSubject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { slideInOutVisible } from 'shared/animations/common-animations';
import { GridFocusDirective } from 'shared/component/grid/ipx-grid-focus.directive';
import { IpxGridOptions } from 'shared/component/grid/ipx-grid-options';
import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import { IpxKendoGridComponent } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxShortcutsService } from 'shared/component/utility/ipx-shortcuts.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';
import * as _ from 'underscore';
import { FileLocationOfficeService } from './file-location-office.service';

@Component({
    selector: 'file-location-offices',
    templateUrl: './file-location-office.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})

export class FileLocationOfficeComponent implements OnInit {
    gridOptions: IpxGridOptions;
    hasChanges$ = new BehaviorSubject<boolean>(false);
    changedRows: Array<number>;
    @ViewChild('fileLocationOfficeGrid', { static: false }) grid: IpxKendoGridComponent;
    @ViewChild('fileLocationOfficeGrid', { static: false, read: GridFocusDirective }) _gridFocus: GridFocusDirective;

    constructor(private readonly service: FileLocationOfficeService,
        private readonly formBuilder: FormBuilder,
        private readonly notificationService: NotificationService,
        private readonly destroy$: IpxDestroy,
        private readonly shortcutsService: IpxShortcutsService) { }

    ngOnInit(): void {
        this.gridOptions = this.buildGridOptions();
        this.handleShortcuts();
    }

    handleShortcuts(): void {
        const shortcutCallbacksMap = new Map(
            [[RegisterableShortcuts.SAVE, (): void => { if (this.hasChanges$.value) { this.save(); } }],
            [RegisterableShortcuts.REVERT, (): void => { if (this.hasChanges$.value) { this.reload(); } }]]);
        this.shortcutsService.observeMultiple$([RegisterableShortcuts.SAVE, RegisterableShortcuts.REVERT])
            .pipe(takeUntil(this.destroy$))
            .subscribe((key: RegisterableShortcuts) => {
                if (!!key && shortcutCallbacksMap.has(key)) {
                    shortcutCallbacksMap.get(key)();
                }
            });
    }

    buildGridOptions(): IpxGridOptions {

        const options: IpxGridOptions = {
            autobind: true,
            navigable: true,
            sortable: true,
            reorderable: false,
            persistSelection: false,
            showGridMessagesUsingInlineAlert: false,
            read$: (queryParams) => {

                return this.service.getFileLocationOffices(queryParams);
            },
            rowMaintenance: {
                rowEditKeyField: 'id'
            },
            customRowClass: (context) => {
                let returnValue = '';
                if (context.dataItem && this.changedRows && this.changedRows.length > 0 && this.changedRows.indexOf(context.dataItem.id) !== -1) {
                    returnValue += ' saved';
                }

                return returnValue;
            },
            // tslint:disable-next-line: unnecessary-bind
            createFormGroup: this.createFormGroup.bind(this),
            alwaysRenderInEditMode: true,
            columns: this.getColumns(),
            onDataBound: (boundData: any) => {
                if (!!boundData && boundData.length > 0) {
                    setTimeout(() => {
                        this._gridFocus.focusFirstEditableField();
                    }, 10);
                }
            },
            selectable: {
                mode: 'single'
            }

        };

        return options;
    }

    createFormGroup = (dataItem: any): FormGroup => {

        const formGroup = this.formBuilder.group({
            id: dataItem.id,
            fileLocation: dataItem.fileLocation,
            office: dataItem.office
        });
        this.gridOptions.formGroup = formGroup;

        return formGroup;
    };

    anyChanges = (): boolean => {
        return _.find(this.grid.rowEditFormGroups, (t: any) => {
            return t.dirty === true;
        });
    };

    checkValidationAndEnableSave = (): void => {
        this.hasChanges$.next(this.grid.isValid() && this.anyChanges());
    };

    save = (): void => {
        if (this.hasChanges$.value) {
            this.changedRows = [];
            const rows = [];
            const keys = Object.keys(this.grid.rowEditFormGroups);
            keys.forEach((r) => {
                if (this.grid.rowEditFormGroups[r].dirty) {
                    const value = this.grid.rowEditFormGroups[r].getRawValue();
                    rows.push(value);
                }
            });
            if (rows.length > 0) {
                this.service.saveFileLocationOffice(rows).subscribe(() => {
                    this.notificationService.success();
                    this.changedRows = [...rows.map(r => r.id)];
                    this.resetForms();
                });
            }
        }
    };

    reload = (): void => {
        this.changedRows = [];
        this.resetForms();
    };

    resetForms = (): void => {
        this.grid.rowEditFormGroups = null;
        this.grid.search();
        this.gridOptions.formGroup.markAsPristine();
        this.hasChanges$.next(false);
    };

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [{
            title: 'fileLocationOffice.column.fileLocation',
            field: 'fileLocation',
            sortable: false
        }, {
            title: 'fileLocationOffice.column.office',
            field: 'office',
            sortable: false,
            template: true
        }];

        return columns;
    };
}