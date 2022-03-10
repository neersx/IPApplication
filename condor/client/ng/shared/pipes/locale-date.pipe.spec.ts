import { DateService } from 'ajs-upgraded-providers/date-service.provider';
import { noop } from 'rxjs';
import { LocaleDatePipe } from './locale-date.pipe';
export class MockDataService extends DateService {
    constructor() { super(); }
}
describe('Local date format pipe', () => {
    let pipe: LocaleDatePipe;

    it('should create an instance', () => {
        const _dateService = new MockDataService();
        pipe = new LocaleDatePipe(_dateService);
        expect(pipe).toBeTruthy();
    });

    it('should convert the date', () => {
        const _dateService = new MockDataService();
        const testdate = '2010-06-19T00:00:00';
        _dateService.dateFormat = 'dd-MMM-yyyy';
        _dateService.culture = 'en';
        _dateService.useDefault = noop;
        const testpipe = new LocaleDatePipe(_dateService);
        expect(testpipe.transform(testdate, '')).toEqual('19-Jun-2010');
    });

    it('should convert the date into datetime format', () => {
        const _dateService = new MockDataService();
        const testdate = '2010-06-19T11:28:42.97';
        _dateService.dateFormat = 'dd-MMM-yyyy';
        _dateService.culture = 'en';
        _dateService.useDefault = noop;
        const testpipe = new LocaleDatePipe(_dateService);
        expect(testpipe.transform(testdate, 'hh:mm:ss a')).toEqual('19-Jun-2010 11:28:42 AM');
    });
});
