import { fakeAsync, tick } from '@angular/core/testing';
import { FormBuilder } from '@angular/forms';
import { ChangeDetectorRefMock, NotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { BehaviorSubject, of } from 'rxjs';
import { AttachmentConfigurationServiceMock } from '../attachments-configuration.service.mock';
import { NetworkDriveMappingMaintenanceComponent } from './network-drive-mapping-maintenance.component';

describe('NetworkDriveMappingMaintenanceComponent', () => {
    let component: (formGroup?: any) => NetworkDriveMappingMaintenanceComponent;
    let modalService: ModalServiceMock;
    let cdr: ChangeDetectorRefMock;
    let notificationService: NotificationServiceMock;
    let service: AttachmentConfigurationServiceMock;

    beforeEach(() => {
        modalService = new ModalServiceMock();
        notificationService = new NotificationServiceMock();
        cdr = new ChangeDetectorRefMock();
        service = new AttachmentConfigurationServiceMock();
        component = (formGroup?: any) => {
            const c = new NetworkDriveMappingMaintenanceComponent(modalService as any, notificationService as any, cdr as any, service as any, new FormBuilder());
            c.onClose$.next = jest.fn((val) => val);
            (c as any).sbsModalRef = {
                hide: jest.fn()
            } as any;
            c.formGroup = {
                dirty: true,
                reset: jest.fn(),
                controls: {
                    driveLetter: {},
                    uncPath: { setErrors: jest.fn(), markAsDirty: jest.fn(), markAsTouched: jest.fn() }
                },
                value: {
                    storageLocationId: 1,
                    driveLetter: 'Z',
                    uncPath: 'c:\\server1'
                }, ...(formGroup || {})
            };

            return c;
        };

    });

    it('should create', () => {
        expect(component()).toBeTruthy();
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
            const c = component({ dirty: true });
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
            service.validateUrl$ = jest.fn(() => of(false));
            const c = component();

            c.apply(null);

            expect(service.validateUrl$).toHaveBeenCalled();
            expect(c.formGroup.controls.uncPath.setErrors).toHaveBeenCalled();
            expect(c.formGroup.controls.uncPath.markAsDirty).toHaveBeenCalled();
            expect(c.formGroup.controls.uncPath.markAsTouched).toHaveBeenCalled();
            expect((c as any).sbsModalRef.hide).not.toHaveBeenCalled();
            expect(c.onClose$.next).not.toHaveBeenCalled();
        });

        it('should close modal if all good', () => {
            const c = component();

            c.apply(null);

            expect(service.validateUrl$).toHaveBeenCalled();
            expect((c as any).sbsModalRef.hide).toHaveBeenCalled();
            expect(c.onClose$.next).toHaveBeenCalledWith({ success: true, formGroup: c.formGroup });
        });

        it('should create formGroup Correctly ', () => {
            const item = {
                networkDriveMappingId: 0,
                driveLetter: 'Z',
                uncPath: 'c:\\server1',
                status: 'adding'
            };
            const c = component();
            c.dataItem = item;
            const fg = c.createFormGroupTemp();
            expect(Object.keys(fg.controls).length).toEqual(4);
            expect(fg.value).toEqual(item);
        });
    });
});
