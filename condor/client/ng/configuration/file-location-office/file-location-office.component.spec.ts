import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder, FormControl, FormGroup } from '@angular/forms';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { NotificationServiceMock } from 'mocks/notification-service.mock';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { FileLocationOfficeComponent } from './file-location-office.component';
import { FileLocationOfficeServiceMock } from './file-location-office.service.mock';

describe('Inprotech.Configuration.Offices', () => {
    let component: FileLocationOfficeComponent;
    let service: FileLocationOfficeServiceMock;
    let notificationService: NotificationServiceMock;
    let formBuilder: FormBuilder;
    let shortcutsService: IpxShortcutsServiceMock;
    let destroy$: any;

    beforeEach(() => {
        service = new FileLocationOfficeServiceMock();
        notificationService = new NotificationServiceMock();
        formBuilder = new FormBuilder();
        shortcutsService = new IpxShortcutsServiceMock();
        destroy$ = of({}).pipe(delay(1000));
        component = new FileLocationOfficeComponent(service as any, formBuilder as any, notificationService as any, destroy$, shortcutsService as any);
        component.grid = new IpxKendoGridComponentMock() as any;
    });

    it('should initialise', () => {
        component.ngOnInit();
        spyOn(component, 'buildGridOptions');

        expect(component.gridOptions).toBeDefined();
        expect(component.gridOptions.columns.length).toBe(2);
        expect(component.gridOptions.columns[0].title).toBe('fileLocationOffice.column.fileLocation');
        expect(component.gridOptions.columns[1].field).toBe('office');
    });

    describe('save', () => {
        beforeEach(() => {
            component.ngOnInit();
            component.hasChanges$.next(true);
            component.gridOptions = { _search: jest.fn().mockReturnValue({}), read$: jest.fn(), columns: [] };
            component.gridOptions.formGroup = { markAsPristine: jest.fn() } as any;
        });

        it('should call save if shortcut is given', fakeAsync(() => {
            component.save = jest.fn();
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
            component.ngOnInit();
            tick(shortcutsService.interval);
            expect(component.save).toHaveBeenCalled();
        }));
        it('should call revert if shortcut is given', fakeAsync(() => {
            component.reload = jest.fn();
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;
            component.ngOnInit();
            tick(shortcutsService.interval);
            expect(component.reload).toHaveBeenCalled();
        }));

        it('should return success notification when save is successful', (done) => {
            component.grid.rowEditFormGroups = {
                ['1']: new FormGroup({
                    fileLocation: new FormControl('abc'),
                    id: new FormControl(1),
                    office: new FormControl({ key: 1 })
                }),
                ['2']: new FormGroup({
                    fileLocation: new FormControl('cde'),
                    id: new FormControl(2),
                    office: new FormControl({ key: 2 })
                })
            };
            const rows = [{ fileLocation: 'abc', id: 1, office: { key: 1 } }, { fileLocation: 'cde', id: 2, office: { key: 2 } }];
            component.grid.rowEditFormGroups['1'].setValue(rows[0]);
            component.grid.rowEditFormGroups['2'].setValue(rows[1]);
            component.grid.rowEditFormGroups['1'].markAsDirty();
            component.grid.rowEditFormGroups['2'].markAsDirty();
            component.save();
            expect(service.saveFileLocationOffice).toHaveBeenCalledWith(rows);
            service.saveFileLocationOffice(rows).subscribe(() => {
                expect(notificationService.success).toHaveBeenCalled();
                expect(component.changedRows).toEqual([1, 2]);
                expect(component.grid.rowEditFormGroups).toEqual(null);
                expect(component.grid.search).toHaveBeenCalled();
                expect(component.hasChanges$.value).toEqual(false);
                done();
            });
        });
        it('should reload form', () => {
            component.reload();
            expect(component.changedRows).toEqual([]);
            expect(component.grid.rowEditFormGroups).toEqual(null);
            expect(component.grid.search).toHaveBeenCalled();
            expect(component.hasChanges$.value).toEqual(false);
        });
    });
});