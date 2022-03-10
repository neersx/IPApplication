import { Observable, of } from 'rxjs';

export class BulkPolicingServiceMock {
    getBulkPolicingViewData = jest.fn().mockReturnValue(of({
        textTypes: [
        {
            key: '1',
            value: 'aaa'
        },
        {
            key: '2',
            value: 'bbb'
        }
    ],
    allowRichText: false}));
    sendBulkPolicingRequest = jest.fn().mockReturnValue(new Observable());
}