import { of } from 'rxjs';
import { ExchangeRateScheduleItems } from './exchange-rate-schedule.model';

export class ExchangeRateScheduleServiceMock {
    private readonly testResponse = new ExchangeRateScheduleItems();
    getExchangeRateSchedule = jest.fn().mockReturnValue(Promise.resolve([this.testResponse]));
    getViewData = jest.fn().mockReturnValue(Promise.resolve([this.testResponse]));
    deleteExchangeRateSchedules = jest.fn().mockReturnValue(of({ result: 'success' }));
}