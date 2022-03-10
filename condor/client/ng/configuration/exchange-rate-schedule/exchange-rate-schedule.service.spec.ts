import { GridNavigationServiceMock, HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { ExchangeRateScheduleRequest } from './exchange-rate-schedule.model';
import { ExchangeRateScheduleService } from './exchange-rate-schedule.service';
describe('ExchangeRateScheduleService', () => {

    let service: ExchangeRateScheduleService;
    let httpMock: HttpClientMock;
    let gridNavigationService: GridNavigationServiceMock;
    beforeEach(() => {
        httpMock = new HttpClientMock();
        gridNavigationService = new GridNavigationServiceMock();
        httpMock.get.mockReturnValue({
            pipe: (args: any) => {
                return [];
            }
        });
        httpMock.put.mockReturnValue(of({}));
        service = new ExchangeRateScheduleService(httpMock as any, gridNavigationService as any);
    });

    it('service should be created', () => {
        expect(service).toBeTruthy();
    });
    it('should get viewData', () => {
        service.getViewData();
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/exchange-rate-schedule/viewdata');
    });
    it('should call the getExchangeRateSchedule api correctly ', () => {
        const criteria = {};
        jest.spyOn(gridNavigationService, 'init');
        service.getExchangeRateSchedule(criteria, null);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/exchange-rate-schedule', { params: { params: 'null', q: JSON.stringify(criteria) } });
    });

    it('should call the getExchangeRateScheduleDetails api correctly ', () => {
        service.getExchangeRateScheduleDetails(1);
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/exchange-rate-schedule/1');
    });

    it('should call the validate exchange rate schedule code api correctly ', () => {
        service.validateExchangeRateScheduleCode('AB');
        expect(httpMock.get).toHaveBeenCalledWith('api/configuration/exchange-rate-schedule/validate/AB');
    });

    const entry: ExchangeRateScheduleRequest = {
        id: 1,
        code: 'AB',
        description: 'Code desc'
    };

    it('calls the correct API passing the parameters', () => {
        service.submitExchangeRateSchedule(entry);
        expect(httpMock.put).toHaveBeenCalledWith('api/configuration/exchange-rate-schedule/1', entry);
    });

    it('calls the correct API passing the parameters', () => {
        entry.id = null;
        service.submitExchangeRateSchedule(entry);
        expect(httpMock.post).toHaveBeenCalledWith('api/configuration/exchange-rate-schedule', entry);
    });

    describe('Deleting Exchange Rate Schedules', () => {
        it('calls the correct API passing the parameters', () => {
            const inUseIds = { ids: ['11'] };
            service.deleteExchangeRateSchedules(['11']);
            expect(httpMock.request).toHaveBeenCalled();
            expect(httpMock.request.mock.calls[0][0]).toBe('delete');
            expect(httpMock.request.mock.calls[0][1]).toBe('api/configuration/exchange-rate-schedule/delete');
            expect(httpMock.request.mock.calls[0][2]).toEqual({ body: inUseIds });

        });
    });
});