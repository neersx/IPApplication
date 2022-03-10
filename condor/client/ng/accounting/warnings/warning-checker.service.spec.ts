import { fakeAsync, tick } from '@angular/core/testing';
import { NotificationServiceMock } from 'ajs-upgraded-providers/notification-service.mock';
import { HttpClientMock, IpxNotificationServiceMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import * as _ from 'underscore';
import { WarningCheckerService } from './warning-checker.service';
import { WarningServiceMock } from './warning.mock';

describe('Service: WarningCheckerService', () => {
  let http: HttpClientMock;
  let modalService: ModalServiceMock;
  let notificationService: IpxNotificationServiceMock;
  let warningService: WarningServiceMock;
  let service: WarningCheckerService;

  beforeEach(() => {
    http = new HttpClientMock();
    modalService = new ModalServiceMock();
    notificationService = new IpxNotificationServiceMock();
    warningService = new WarningServiceMock();

    service = new WarningCheckerService(http as any, modalService as any, notificationService as any, warningService as any);
  });
  it('should create an instance', () => {
    expect(service).toBeTruthy();
  });

  describe('performCaseWarningsCheck', () => {
    it('should return true, if caseKey not provided', done => {
      service.performCaseWarningsCheck(null, new Date())
        .subscribe((result) => {
          expect(result).toBeTruthy();

          done();
        });
    });

    it('should call to check status', done => {
      http.get.mockReturnValue(of(false));
      service.performCaseWarningsCheck(100, new Date())
        .subscribe(() => {
          expect(http.get).toHaveBeenCalledWith('api/accounting/time/checkstatus/100');

          done();
        });
    });

    it('should display message and return false, if case status returns false', done => {
      http.get.mockReturnValue(of(false));
      service.performCaseWarningsCheck(100, new Date())
        .subscribe((result) => {
          expect(notificationService.openAlertModal).toHaveBeenCalled();
          expect(notificationService.openAlertModal.mock.calls[0][1]).toBe('accounting.wip.caseStatusRestrictedFor');

          expect(result).toBeFalsy();

          done();
        });
    });

    it('should perform case-name warning check, if case status returns ok', fakeAsync(() => {
      http.get.mockReturnValue(of(true));
      warningService.getCasenamesWarnings.mockReturnValue(of());
      const currentDate = new Date();
      service.performCaseWarningsCheck(100, currentDate).subscribe();
      tick();
      expect(warningService.getCasenamesWarnings).toHaveBeenCalledWith(100, currentDate);
    }));
  });

  describe('performCaseWarningsCheck - case name warnings', () => {
    it('case names warning dialog is displayed if appropriate', fakeAsync(() => {
      http.get = jest.fn().mockReturnValue(of(true));
      modalService.modalRef.content = { btnClicked: of(), onBlocked: of() };

      warningService.getCasenamesWarnings
        .mockReturnValueOnce(of({ budgetCheckResult: true }))
        .mockReturnValueOnce(of({ prepaymentCheckResult: { exceeded: true } }))
        .mockReturnValueOnce(of({ billingCapCheckResult: [1, 2, 3] }))
        .mockReturnValueOnce(of({ caseWipWarnings: [{ caseName: { debtorStatusActionFlag: true, enforceNameRestriction: true } }] }))
        .mockReturnValueOnce(of({ caseWipWarnings: [{ caseName: { debtorStatusActionFlag: null }, creditLimitCheckResult: { exceeded: true } }] }))
        .mockReturnValueOnce(of({ caseWipWarnings: [{ caseName: { debtorStatusActionFlag: true, enforceNameRestriction: false } }] }));

      _.times(5, (n) => {
        const sub = service.performCaseWarningsCheck(100).subscribe();
        tick();
        expect(modalService.openModal).toHaveBeenCalledTimes(n + 1);
        sub.unsubscribe();
      });
    }));

    it('returns true, if warnings blocked are ignored', done => {
      http.get = jest.fn().mockReturnValueOnce(of(true));
      warningService.getCasenamesWarnings.mockReturnValueOnce(of({ budgetCheckResult: true }));
      modalService.content = { btnClicked: of(true).pipe(delay(500)), onBlocked: of(false) };

      service.performCaseWarningsCheck(100, new Date()).subscribe((result) => {
        expect(result).toBeTruthy();

        done();
      });
    });

    it('returns false, if warning dialog is cancelled', done => {
      http.get = jest.fn().mockReturnValueOnce(of(true));
      warningService.getCasenamesWarnings.mockReturnValueOnce(of({ budgetCheckResult: true }));
      modalService.content = { btnClicked: of(true).pipe(delay(800)), onBlocked: of(true).pipe(delay(1000)) };

      service.performCaseWarningsCheck(100, new Date()).subscribe((result) => {
        expect(result).toBeFalsy();

        done();
      });
    });

    it('returns true, if warning is not required to be displayed', () => {
      http.get = jest.fn().mockReturnValueOnce(of(true));

      warningService.getCasenamesWarnings.mockReturnValueOnce(of({ budgetCheckResult: false }));
      service.performCaseWarningsCheck(100, new Date()).subscribe((result) => {
        expect(modalService.openModal).not.toHaveBeenCalled();

        expect(result).toBeTruthy();
      });
    });
  });

  describe('performNameWarningsCheck', () => {
    it('should return true, is name key is not provided', done => {
      service.performNameWarningsCheck(null, 'ABCD', new Date()).subscribe((result) => {
        expect(result).toBeTruthy();

        done();
      });
    });

    it('should call names warning, returns true if warning service did not return any warnings', fakeAsync(() => {
      warningService.getWarningsForNames.mockReturnValue(of());
      const currentDate = new Date();
      service.performNameWarningsCheck(10, 'ABCD', currentDate).subscribe((result) => {
        expect(result).toBeTruthy();
      });

      tick();
      expect(warningService.getWarningsForNames).toHaveBeenCalledWith(10, currentDate);
    }));
  });

  describe('performNameWarningsCheck - names warnings', () => {
    it('names warning dialog is displayed if appropriate', fakeAsync(() => {
      modalService.modalRef.content = { btnClicked: of(), onBlocked: of() };

      warningService.getWarningsForNames
        .mockReturnValueOnce(of({ restriction: true }))
        .mockReturnValueOnce(of({ creditLimitCheckResult: { exceeded: true } }))
        .mockReturnValueOnce(of({ prepaymentCheckResult: { exceeded: true } }))
        .mockReturnValueOnce(of({ billingCapCheckResult: [1, 2, 3] }));

      _.times(4, (n) => {
        const sub = service.performNameWarningsCheck(100, 'ABCD', new Date()).subscribe();
        tick();
        expect(modalService.openModal).toHaveBeenCalledTimes(n + 1);
        sub.unsubscribe();
      });
    }));

    it('returns true, if warnings blocked are ignored', fakeAsync(() => {
      warningService.getWarningsForNames.mockReturnValueOnce(of({ restriction: true }));
      modalService.content = { btnClicked: of(true).pipe(delay(500)), onBlocked: of(false) };

      service.performNameWarningsCheck(100, 'ABCD', new Date()).subscribe((result) => {
        expect(result).toBeTruthy();
      });

      tick(500);
    }));

    it('returns true, if warning dialog is proceeded', fakeAsync(() => {
      http.get = jest.fn().mockReturnValueOnce(of(true));
      warningService.getWarningsForNames.mockReturnValueOnce(of({ restriction: true }));
      modalService.content = { btnClicked: of(true).pipe(delay(400)), onBlocked: of(true).pipe(delay(1000)) };

      service.performNameWarningsCheck(100, 'ABCD', new Date()).subscribe((result) => {
        expect(result).toBeTruthy();
      });

      tick(400);
    }));

    it('returns false, if warning dialog is cancelled', fakeAsync(() => {
      http.get = jest.fn().mockReturnValueOnce(of(true));
      warningService.getWarningsForNames.mockReturnValueOnce(of({ restriction: true }));
      modalService.content = { btnClicked: of(true).pipe(delay(800)), onBlocked: of(true).pipe(delay(1000)) };

      service.performNameWarningsCheck(100, 'ABCD', new Date()).subscribe((result) => {
        expect(result).toBeFalsy();
      });

      tick(500);
    }));

    it('should return true, if no warnings to be displayed', done => {
      warningService.getWarningsForNames.mockReturnValue(of({}));
      const currentDate = new Date();
      service.performNameWarningsCheck(10, 'ABCD', currentDate).subscribe((result) => {
        expect(result).toBeTruthy();

        done();
      });
    });
  });
});
