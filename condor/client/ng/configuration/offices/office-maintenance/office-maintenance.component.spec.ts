import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder, FormGroup } from '@angular/forms';
import { RegisterableShortcuts } from 'core/registerable-shortcuts.enum';
import { BsModalRefMock, ChangeDetectorRefMock, GridNavigationServiceMock, HttpClientMock } from 'mocks';
import { IpxNotificationServiceMock } from 'mocks/notification-service.mock';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { IpxShortcutsServiceMock } from 'shared/component/utility/ipx-shortcuts.service.mock';
import { OfficeServiceMock } from '../offices.service.mock';
import { OfficeMaintenanceComponent } from './office-maintenance.component';

describe('OfficeMaintainenaceComponent', () => {
    let component: OfficeMaintenanceComponent;
    let notificationServiceMock: IpxNotificationServiceMock;
    let httpMock: HttpClientMock;
    let service: OfficeServiceMock;
    let gridNavigationService: GridNavigationServiceMock;
    let formBuilder: FormBuilder;
    let cdRef: ChangeDetectorRefMock;
    let shortcutsService: IpxShortcutsServiceMock;
    let destroy$: any;
    beforeEach(() => {
        httpMock = new HttpClientMock();
        httpMock.get.mockReturnValue(of({ id: 1, textType: 1 }));
        httpMock.post.mockReturnValue(of({}));
        gridNavigationService = new GridNavigationServiceMock();
        formBuilder = new FormBuilder();
        cdRef = new ChangeDetectorRefMock();
        shortcutsService = new IpxShortcutsServiceMock();
        destroy$ = of({}).pipe(delay(1000));
        service = new OfficeServiceMock();
        notificationServiceMock = new IpxNotificationServiceMock();
        component = new OfficeMaintenanceComponent(service as any, notificationServiceMock as any, formBuilder as any, new BsModalRefMock(), cdRef as any, gridNavigationService as any,
            destroy$, shortcutsService as any);
        component.navData = {
            keys: [{ key: '1', value: '-134' }, { key: '2', value: '21' }, { key: '3', value: '-133' }, { key: '4', value: '51' }],
            totalRows: 4,
            pageSize: 0,
            fetchCallback: jest.fn()
        };
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('should initialize on ngOnInit with appropriate state add', () => {
        spyOn(component, 'loadData');
        component.state = 'Add';
        component.ngOnInit();
        expect(service.getRegions).toHaveBeenCalled();
        expect(component.entry).toBeDefined();
        expect(component.entry.id).toBeNull();
    });

    it('should initialize on ngOnInit with appropriate state edit', (done) => {
        service.getOffice = jest.fn().mockReturnValue(of({
            id: 21,
            description: null,
            organization: null,
            country: null,
            language: null,
            userCode: '12',
            cpaCode: '23',
            irnCode: null,
            itemNoPrefix: null,
            itemNoTo: null,
            itemNoFrom: null,
            printerCode: 1201,
            regionCode: null
        }));
        jest.spyOn(component, 'loadData');
        jest.spyOn(gridNavigationService, 'getNavigationData').mockReturnValue(component.navData);
        component.state = 'Edit';
        component.entryId = 21;
        component.ngOnInit();
        service.getOffice(21).subscribe(res => {
            expect(res).toBeDefined();
            expect(component.loadData).toHaveBeenCalled();
            expect(component.entry).toBeDefined();
            expect(component.entry.id).toBe(21);
            expect(component.canNavigate).toBe(true);
            expect(component.navData.keys).toEqual([{ key: '1', value: '-134' }, { key: '2', value: '21' }, { key: '3', value: '-133' }, { key: '4', value: '51' }]);
            expect(component.currentKey).toEqual('2');
            done();
        });
    });

    it('should set formGroup appropriately with entry object', () => {
        component.entryId = 21;
        jest.spyOn(gridNavigationService, 'getNavigationData').mockReturnValue(component.navData);
        component.ngOnInit();
        component.entry = {
            id: 2,
            description: null,
            organization: null,
            country: null,
            language: null,
            userCode: '12',
            cpaCode: '23',
            irnCode: null,
            itemNoPrefix: null,
            itemNoTo: null,
            itemNoFrom: null,
            printerCode: 1201,
            regionCode: null
        };
        component.loadData();
        expect(component.formGroup.value.userCode).toEqual(component.entry.userCode);
        expect(component.formGroup.value.printerCode).toEqual(component.entry.printerCode);
        expect(component.formGroup.value.organization).toBe(null);
    });
    it('should set From and To null when prefix is null', () => {
        component.state = 'Add';
        component.ngOnInit();
        component.itemNoFrom.setValue(100);
        component.itemNoTo.setValue(200);
        component.setFromTo('');
        expect(component.itemNoFrom.value).toBe(null);
        expect(component.itemNoFrom.value).toBe(null);
    });

    it('should set country null when organisation is null', () => {
        component.state = 'Add';
        component.ngOnInit();
        component.country.setValue({ code: 'AU', value: 'Australia' });
        component.onChangeOrganisation('');
        expect(component.country.value).toBe(null);
        expect(component.isCountryDisabled).toBe(false);
    });
    it('should set country value from organisation', () => {
        component.state = 'Add';
        component.ngOnInit();
        component.onChangeOrganisation({ key: 1, countryCode: 'AU', countryName: 'Australua' });
        expect(component.country.value.code).toBe('AU');
        expect(component.country.value.value).toBe('Australua');
        expect(component.isCountryDisabled).toBe(true);
    });

    describe('Office Save', () => {
        beforeEach(() => {
            component.onClose$.next = jest.fn() as any;
            (component as any).sbsModalRef = {
                hide: jest.fn()
            } as any;
            component.state = 'Add';
            component.ngOnInit();
        });
        it('should call save if shortcut is given', fakeAsync(() => {
            component.save = jest.fn();
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.SAVE;
            component.ngOnInit();
            tick(shortcutsService.interval);
            expect(component.save).toHaveBeenCalled();
        }));
        it('should call revert if shortcut is given', fakeAsync(() => {
            component.cancel = jest.fn();
            shortcutsService.observeMultipleReturnValue = RegisterableShortcuts.REVERT;
            component.ngOnInit();
            tick(shortcutsService.interval);
            expect(component.cancel).toHaveBeenCalled();
        }));
        it('save form changes', (done) => {
            component.formGroup.setValue({
                id: 1,
                description: 'ABC',
                organization: null,
                country: null,
                regionCode: null,
                language: null,
                printerCode: null,
                userCode: null,
                cpaCode: null,
                irnCode: null,
                itemNoPrefix: null,
                itemNoTo: null,
                itemNoFrom: null
            });
            component.formGroup.controls.language.markAsDirty();
            component.save();
            service.saveOffice(component.formGroup.value).subscribe(() => {
                expect(component.onClose$.next).toHaveBeenCalledWith(true);
                expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
                done();
            });
        });

        it('should handle error while saving form changes', (done) => {
            service.saveOffice = jest.fn().mockReturnValue(of({ errors: [{ message: 'as' }] }));
            component.formGroup.controls.language.markAsDirty();
            component.save();
            service.saveOffice(null).subscribe((res) => {
                expect(res.errors).toBeDefined();
                done();
            });
        });

        it('should reset form', () => {
            component.resetForm();
            expect(component.onClose$.next).toHaveBeenCalledWith(false);
            expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
        });
        it('cancel form changes', () => {
            component.formGroup = new FormGroup({});
            (component as any).formGroup = {
                reset: jest.fn()
            } as any;
            component.cancel();
            expect(component.formGroup.reset).toHaveBeenCalled();
        });
    });
});