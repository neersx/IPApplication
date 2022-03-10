import { HttpErrorResponse } from '@angular/common/http';
import { ModalServiceMock } from 'ajs-upgraded-providers/modal-service.mock';
import { NotificationServiceMock } from 'ajs-upgraded-providers/notification-service.mock';
import { TranslateServiceMock } from 'mocks';
import { of, Subject, throwError } from 'rxjs';
import { AppContextServiceMock } from './app-context.service.mock';
import { CoreInterceptor } from './core-interceptor';

describe('Angular Error Interceptor', () => {
    let interceptor: CoreInterceptor;
    const request: any = {};
    let notification: NotificationServiceMock;
    // tslint:disable-next-line: one-variable-per-declaration
    const status1 = 'status-1',
        status403 = 'status-403',
        status500 = 'status-500',
        status500token = 'status-500-with-token',
        statusOther = 'status-other',
        failureMsg = {
            title: 'Error',
            message: 'common.errors.status-other',
            okButton: 'Ok'
        };
    const translations = {
        'common.errors.status-1': status1,
        'common.errors.status-403': status403,
        'common.errors.status-500': status500,
        'common.errors.status-500-with-token': status500token + '-{{correlationId}}',
        'common.errors.status-other': statusOther
    };

    const buildFailedResponse = (status, token?): HttpErrorResponse => {
        return new HttpErrorResponse({
            status,
            error: {
                correlationId: token
            }
        });
    };

    const expectForFailedResponse = (statusCode: number, done, expectation, correlationId?) => {
        const observable = new Subject();
        const next = {
            handle: () => observable.asObservable()
        };
        // tslint:disable-next-line: no-empty
        interceptor.intercept(request, next as any).subscribe(() => { }, () => {
            expectation();
            done();
        });

        observable.error(buildFailedResponse(statusCode, correlationId));
    };
    const translate = new TranslateServiceMock();
    translate.get = jest.fn((msg: string, keys?) => {
        let message: string = translations[msg];
        if (keys) {
            Object.keys(keys).forEach(k => {
                message = message.replace('{{' + k + '}}', k);
            });
        }

        return of(message);
    });

    beforeEach(() => {
        notification = new NotificationServiceMock();
        const modal = new ModalServiceMock();
        const appContext = new AppContextServiceMock();
        interceptor = new CoreInterceptor(notification as any, modal as any, translate as any, appContext as any);
    });

    it('notifies the right message on 403', (done) => {
        expectForFailedResponse(403, done, () => {
            expect(notification.alert).toHaveBeenCalledWith({
                message: status403
            });
        });
    });

    it('notifies the right message on 500', (done) => {
        expectForFailedResponse(500, done, () => {
            expect(notification.alert).toHaveBeenCalledWith({
                message: status500
            });
        });
    });

    it('notifies the right message on 1', (done) => {
        expectForFailedResponse(1, done, () => {
            expect(notification.alert).toHaveBeenCalledWith({
                message: status1
            });
        });
    });

    it('notifies the right message on 500 and correlationId', (done) => {
        expectForFailedResponse(500, done, () => {
            expect(notification.alert).toHaveBeenCalledWith({
                message: status500token + '-correlationId'
            });
        }, 'correlationId');
    });

    it('notifies the right message on any other error status', (done) => {
        expectForFailedResponse(2, done, () => {
            expect(notification.alert).toHaveBeenCalledWith({
                message: statusOther
            });
        });
    });

    it('notifies the right message on translation failure', (done) => {
        // tslint:disable-next-line: no-string-literal
        translate.get = jest.fn(msg => throwError('')); // translate a language we don't have translations for

        expectForFailedResponse(2, done, () => {
            expect(notification.alert).toHaveBeenCalledWith(failureMsg);
        });
    });

    it('does not notify if the request was cancelled', (done) => {
        expectForFailedResponse(-1, done, () => {
            expect(notification.alert).not.toHaveBeenCalled();
        });
    });

    // Functionality not implemented yet
    xit('does not notify if handlesError is true', () => {
        const r = buildFailedResponse(500);
        // r.config.handlesError = true;
        // interceptor.responseError(r);
        // $rootScope.$digest();
        // expect(notificationService.alert).not.toHaveBeenCalled();
    });

    xit('does not notify if handlesError returns true', () => {
        const r = buildFailedResponse(500);
        // r.config.handlesError = function() {
        //     return true;
        // };
        // interceptor.responseError(r);
        // $rootScope.$digest();
        // expect(notificationService.alert).not.toHaveBeenCalled();
    });

    xit('does notify if handlesError returns false', () => {
        const r = buildFailedResponse(500);
        // r.config.handlesError = function() {
        //     return false;
        // };
        // interceptor.responseError(r);
        // $rootScope.$digest();
        // expect(notificationService.alert).toHaveBeenCalledWith({
        //     message: status500
        // });
    });

    xit('calls handlesError with correct parameters', () => {
        const r = buildFailedResponse(500);
        // r.config.handlesError = jasmine.createSpy().and.returnValue(true);
        // interceptor.responseError(r);
        // $rootScope.$digest();
        // expect(r.config.handlesError).toHaveBeenCalledWith(r.data, 500, r);
    });
});