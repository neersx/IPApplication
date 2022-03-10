import { CaseTopicsDataService } from './case-topics-data.service';

describe('CaseTopicsDataService', () => {
    let service: CaseTopicsDataService;

    beforeEach(() => {
        service = new CaseTopicsDataService();
    });
    it('getTopicExistingViewModel should default topic form data', () => {
        const data = service.getTopicsDefaultModel();
        expect(data.length).toEqual(11);
        expect(data[0].topicKey).toEqual('Details');
    });
});
