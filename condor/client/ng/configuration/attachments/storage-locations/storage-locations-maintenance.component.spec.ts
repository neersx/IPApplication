import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { ChangeDetectorRefMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BehaviorSubject, of } from 'rxjs';
import { AttachmentConfigurationServiceMock } from '../attachments-configuration.service.mock';
import { AttachmentsStorageLocationsMaintenanceComponent } from './storage-locations-maintenance.component';

describe('AttachmentsStorageLocationsMaintenanceComponent', () => {
    let component: (formGroup?: any) => AttachmentsStorageLocationsMaintenanceComponent;
    let modalService: ModalServiceMock;
    let cdr: ChangeDetectorRefMock;
    let notificationService: NotificationServiceMock;
    let validateUrl$: any;

    beforeEach(() => {
        modalService = new ModalServiceMock();
        notificationService = new NotificationServiceMock();
        cdr = new ChangeDetectorRefMock();
        validateUrl$ = jest.fn(() => of(true));
        component = (formGroup?: any) => {
            const c = new AttachmentsStorageLocationsMaintenanceComponent(modalService as any, notificationService as any, cdr as any, new FormBuilder());
            c.onClose$.next = jest.fn((val) => val);
            c.validateUrl$ = validateUrl$;
            (c as any).sbsModalRef = {
                hide: jest.fn()
            } as any;
            c.formGroup = {
                dirty: true,
                reset: jest.fn(),
                controls: {
                    name: {},
                    path: { setErrors: jest.fn(), markAsDirty: jest.fn(), markAsTouched: jest.fn() }
                },
                value: {
                    storageLocationId: 1,
                    name: 'folder1',
                    path: 'c:\\server1'
                }, ...(formGroup || {})
            };

            return c;
        };

    });

    it('should create', () => {
        expect(component()).toBeTruthy();
    });

    it('should create formGroup Correctly ', () => {
        const item = {
            storageLocationId: 0,
            canUpload: null,
            name: 'folder1',
            path: 'c:\\server1',
            allowedFileExtensions: 'doc,docx,pdf,csv,xml,ppt,pptx,odt,ods,xls,xlsx,html',
            status: 'adding'
        };
        const c = component();
        c.dataItem = item;
        const fg = c.createFormGroupTemp(item);
        expect(Object.keys(fg.controls).length).toEqual(6);
        expect(fg.value).toEqual(item);
    });

    describe('cancel', () => {
        it('should cancel without modal if no changes', () => {
            const c = component({ dirty: false });
            c.cancel();
            expect(notificationService.openDiscardModal).not.toHaveBeenCalled();
            expect(c.formGroup.reset).not.toHaveBeenCalled();
            expect(c.onClose$.next).toHaveBeenCalledWith({ success: undefined, formGroup: c.formGroup });
            expect((c as any).sbsModalRef.hide).toHaveBeenCalled();
        });

        it('should reset form if adding', fakeAsync(() => {
            const c = component();
            c.isAdding = true;
            c.grid = { rowCancelHandler: jest.fn() };
            notificationService.openDiscardModal.mockReturnValue({ content: { confirmed$: new BehaviorSubject('') } });
            c.cancel();
            tick(100);
            expect(notificationService.openDiscardModal).toHaveBeenCalled();
            expect(c.grid.rowCancelHandler).toHaveBeenCalled();
            expect(c.formGroup.reset).toHaveBeenCalled();
            expect(c.onClose$.next).toHaveBeenCalledWith({ success: undefined, formGroup: c.formGroup });
            expect((c as any).sbsModalRef.hide).toHaveBeenCalled();
        }));

        it('should close form', () => {
            const c = component();

            notificationService.openDiscardModal.mockReturnValue({ content: { confirmed$: new BehaviorSubject('') } });
            c.cancel();
            expect(notificationService.openDiscardModal).toHaveBeenCalled();
            expect(c.formGroup.reset).not.toHaveBeenCalled();
            expect(c.onClose$.next).toHaveBeenCalledWith({ success: undefined, formGroup: c.formGroup });
            expect((c as any).sbsModalRef.hide).toHaveBeenCalled();
        });
    });

    describe('apply', () => {
        it('should not proceed if dirty or Invalid', () => {
            const c = component({ dirty: false });
            const test = () => {
                c.apply(null);

                expect((c as any).sbsModalRef.hide).not.toHaveBeenCalled();
                expect(c.onClose$.next).not.toHaveBeenCalled();
            };
            test();

            c.formGroup = { ...c.formGroup, dirty: true, status: 'INVALID' } as any;
            test();
        });

        it('should set error if path is invalid', () => {
            validateUrl$ = jest.fn(() => of(false));
            const c = component();

            c.apply(null);

            expect(validateUrl$).toHaveBeenCalled();
            expect(c.formGroup.controls.path.setErrors).toHaveBeenCalled();
            expect(c.formGroup.controls.path.markAsDirty).toHaveBeenCalled();
            expect(c.formGroup.controls.path.markAsTouched).toHaveBeenCalled();
            expect((c as any).sbsModalRef.hide).not.toHaveBeenCalled();
            expect(c.onClose$.next).not.toHaveBeenCalled();
        });

        it('should close modal if all good', () => {
            const c = component();

            c.apply(null);

            expect(validateUrl$).toHaveBeenCalled();
            expect((c as any).sbsModalRef.hide).toHaveBeenCalled();
            expect(c.onClose$.next).toHaveBeenCalledWith({ success: true, formGroup: c.formGroup });
        });

    });
});
