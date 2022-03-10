import { discardPeriodicTasks, fakeAsync, flushMicrotasks, tick } from '@angular/core/testing';
import { IpxNotificationServiceMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { HideEvent } from 'shared/component/modal/modal.service';
import { PostTimeDialogService } from './post-time-dialog.service';
import { PostTimeResponseDlgComponent } from './post-time-response-dlg/post-time-response-dlg.component';
import { PostTimeComponent } from './post-time.component';
import { PostResult } from './post-time.model';

describe('Service: PostTimeDialog.service', () => {
    let modalService: ModalServiceMock;
    let postTimeService: any;
    let notificationService: IpxNotificationServiceMock;
    let localDatePipe: any;
    let translate: TranslateServiceMock;
    let notification: any;

    beforeEach(() => {
        modalService = new ModalServiceMock();
        postTimeService = { postResult$: of() };
        notificationService = new NotificationServiceMock();
        localDatePipe = { transform: jest.fn(d => d) };
        translate = new TranslateServiceMock();
        notification = new NotificationServiceMock();
    });

    it('should create an instance', () => {
        const service = new PostTimeDialogService(modalService as any, postTimeService, notificationService as any, translate as any, localDatePipe, notification);
        expect(service).toBeTruthy();
    });

    it('showDialog should display the post dialog', () => {
        const service = new PostTimeDialogService(modalService as any, postTimeService, notificationService as any, translate as any, localDatePipe, notification);
        modalService.openModal = jest.fn().mockReturnValue({
            content: {
                postInitiated: of()
            }
        });
        const input = { staffNameId: 10 };
        const canPostForAllStaff = true;
        const currentDate = new Date();
        service.showDialog(input, canPostForAllStaff, currentDate);
        expect(modalService.openModal).toHaveBeenCalled();
        expect(modalService.openModal.mock.calls[0][0]).toEqual(PostTimeComponent);
        expect(modalService.openModal.mock.calls[0][1].initialState).toEqual({canPostForAllStaff, currentDate, postEntryDetails: input });
    });

    it('should return false if no post is performed', fakeAsync(() => {
        const service = new PostTimeDialogService(modalService as any, postTimeService, notificationService as any, translate as any, localDatePipe, notification);
        modalService.openModal = jest.fn().mockReturnValue({
            content: {
                postInitiated: of().pipe(delay(100))
            }
        });

        modalService.returnValueonHide$ = of(new HideEvent('esc')).pipe(delay(10));

        const r$ = service.showDialog(null, null, null);
        r$.subscribe((result) => {
            expect(result).toBeFalsy();
        });

        tick(10);
    }));

    it('after post completion- case office entity error should be displayed if error recieved', fakeAsync(() => {
        const result = { hasOfficeEntityError: true, rowsPosted: 0 } as any as PostResult;
        postTimeService.postResult$ = of(result).pipe(delay(100));
        const service = new PostTimeDialogService(modalService as any, postTimeService, notificationService as any, translate as any, localDatePipe, notification);
        tick(100);

        expect(notificationService.openAlertModal).toHaveBeenCalled();
        expect(notificationService.openAlertModal.mock.calls[0][0]).toBe('accounting.time.postTime.officeEntityError.title');
        expect(notificationService.openAlertModal.mock.calls[0][1]).toBe('accounting.time.postTime.officeEntityError.message');
    }));

    it('after post completion- error should be displayed if error received and no data param is available', fakeAsync(() => {
        const error = { alertID: 'XYZ555', contextArguments: [] };
        const result = { hasOfficeEntityError: false, rowsPosted: 0, hasError: true, error } as any as PostResult;
        postTimeService.postResult$ = of(result).pipe(delay(100));
        const service = new PostTimeDialogService(modalService as any, postTimeService, notificationService as any, translate as any, localDatePipe, notification);
        tick(100);

        expect(notificationService.openAlertModal).toHaveBeenCalled();
        expect(notificationService.openAlertModal.mock.calls[0][0]).toBe('accounting.time.postTime.officeEntityError.title');
        expect(notificationService.openAlertModal.mock.calls[0][1]).toBe('accounting.errors.XYZ555');
        expect(localDatePipe.transform).not.toHaveBeenCalled();
        expect(translate.instant).toHaveBeenCalledWith('accounting.errors.XYZ555', { value: null });
    }));

    it('after post completion- error should be displayed with date if error received and data param is available', fakeAsync(() => {
        const error = { alertID: 'ABC123', contextArguments: ['2000-01-01'] };
        const result = { hasOfficeEntityError: false, rowsPosted: 0, hasError: true, error } as any as PostResult;
        postTimeService.postResult$ = of(result).pipe(delay(100));
        const service = new PostTimeDialogService(modalService as any, postTimeService, notificationService as any, translate as any, localDatePipe, notification);
        tick(100);

        expect(notificationService.openAlertModal).toHaveBeenCalled();
        expect(notificationService.openAlertModal.mock.calls[0][0]).toBe('accounting.time.postTime.officeEntityError.title');
        expect(notificationService.openAlertModal.mock.calls[0][1]).toBe('accounting.errors.ABC123');
        expect(localDatePipe.transform).toHaveBeenCalledWith(new Date('2000-01-01'), null);
        expect(translate.instant).toHaveBeenCalledWith('accounting.errors.ABC123', {value: new Date('2000-01-01')});
    }));

    it('after post completion- success should be displayed, if successful', fakeAsync(() => {
        const result = { hasOfficeEntityError: false, rowsPosted: 10 } as any as PostResult;
        postTimeService.postResult$ = of(result).pipe(delay(100));
        const service = new PostTimeDialogService(modalService as any, postTimeService, notificationService as any, translate as any, localDatePipe, notification);
        tick(100);

        expect(modalService.openModal).toHaveBeenCalled();
        expect(modalService.openModal.mock.calls[0][0]).toBe(PostTimeResponseDlgComponent);
        expect(modalService.openModal.mock.calls[0][1].initialState).toEqual(result);
        discardPeriodicTasks();
    }));

    it('after post completion- post performed should be passed back as true', fakeAsync(() => {
        const result = { hasOfficeEntityError: false, rowsPosted: 10 } as any as PostResult;
        postTimeService.postResult$ = of(result).pipe(delay(100));
        const service = new PostTimeDialogService(modalService as any, postTimeService, notificationService as any, translate as any, localDatePipe, notification);

        modalService.openModal = jest.fn().mockReturnValue({
            content: {
                postInitiated: of({}).pipe(delay(10))
            }
        });
        modalService.returnValueonHide$ = of(new HideEvent()).pipe(delay(20));

        service.showDialog(null, null, null).subscribe((r) => {
            expect(r).toBeTruthy();
        });

        tick(10);
        tick(100);
        tick(20);
    }));

    it('displays success message when posting in background', fakeAsync(() => {
        const result = { hasOfficeEntityError: false, isBackground: true } as any as PostResult;
        postTimeService.postResult$ = of(result).pipe(delay(100));
        const service = new PostTimeDialogService(modalService as any, postTimeService, notificationService as any, translate as any, localDatePipe, notification);
        tick(100);
        expect(notification.success).toHaveBeenCalledTimes(1);
    }));
});
