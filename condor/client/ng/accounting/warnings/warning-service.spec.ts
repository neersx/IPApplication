import { HttpClientMock, TranslateServiceMock } from 'mocks';
import { WarningService } from './warning-service';

let service: WarningService;
let httpClient: any;
let translateService: any;

beforeEach(() => {
    httpClient = new HttpClientMock();
    translateService = new TranslateServiceMock();
    service = new WarningService(httpClient, translateService);
});
describe('Warnings Service', () =>  {
    it('calls the validate api with correct parameters', () => {
        service.validate(5552368, 'ABCxyz123');
        expect(httpClient.post).toHaveBeenCalledWith('api/accounting/warnings/validate/', {
            nameId: 5552368,
            clearTextPassword: 'ABCxyz123'
        });
    });
    it('calls the correct API for name warnings', () => {
        const toLocalDate = spyOn(WarningService, 'toLocalDate');
        service.getWarningsForNames(101, new Date());
        expect(toLocalDate).toHaveBeenCalled();
        expect(httpClient.get.mock.calls[0][0]).toBe('api/accounting/warnings/name/101');
    });
    it('calls the correct API for case name warnings', () => {
        const toLocalDate = spyOn(WarningService, 'toLocalDate');
        service.getCasenamesWarnings(102, new Date());
        expect(toLocalDate).toHaveBeenCalled();
        expect(httpClient.get.mock.calls[0][0]).toBe('api/accounting/warnings/case/102');
    });
});
describe('Set Period Type description', () => {
    it('sets the period type for days', () => {
        const output = service.setPeriodTypeDescription({ periodType: 'D', period: 123});
        expect(output).toEqual('accounting.wip.warningMsgs.billingCap.periodConcatenation_Days');
    });
    it('sets the period type for weeks', () => {
        const output = service.setPeriodTypeDescription({ periodType: 'W', period: 234 });
        expect(output).toEqual('accounting.wip.warningMsgs.billingCap.periodConcatenation_Weeks');
    });
    it('sets the period type for months', () => {
        const output = service.setPeriodTypeDescription({ periodType: 'M', period: 345 });
        expect(output).toEqual('accounting.wip.warningMsgs.billingCap.periodConcatenation_Months');
    });
    it('sets the period type for years', () => {
        const output = service.setPeriodTypeDescription({ periodType: 'Y', period: 456 });
        expect(output).toEqual('accounting.wip.warningMsgs.billingCap.periodConcatenation_Years');
    });
    it('returns null if not handled', () => {
        const output = service.setPeriodTypeDescription({ periodType: 'X', period: 987 });
        expect(output).toBeNull();
    });
});