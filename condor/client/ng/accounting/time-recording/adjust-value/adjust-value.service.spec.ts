import { HttpClientMock } from 'mocks';
import { TimeEntry } from '../time-recording-model';
import { AdjustValueService, TimeCost } from './adjust-value.service';

describe('Adjust values service', () => {
    let httpClient: any;
    let service: AdjustValueService;

    beforeEach(() => {
        httpClient = new HttpClientMock();
        service = new AdjustValueService(httpClient);
    });

    it('calls the correct endpoint for previewing cost', () => {
        const data = new TimeCost();
        service.previewCost(data);
        expect(httpClient.post).toHaveBeenCalledWith('api/accounting/time/cost-preview', data);
    });

    it('calls the correct endpoint for saving adjusted values', () => {
        const data = new TimeEntry();
        service.saveAdjustedValues(data);
        expect(httpClient.put).toHaveBeenCalledWith('api/accounting/time/adjust-value', data);
    });
});