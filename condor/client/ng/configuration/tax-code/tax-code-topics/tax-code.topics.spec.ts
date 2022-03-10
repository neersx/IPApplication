import { TaxCodeOverviewTopic, TaxCodeRatesTopic } from './tax-code.topics';
describe('TaxCodeOverviewTopic', () => {
    let overviewComponent: TaxCodeOverviewTopic;
    let ratesComponent: TaxCodeRatesTopic;
    const params = {
        viewData: {
            taxRateId: 1
        }
    };
    beforeEach(() => {
        overviewComponent = new TaxCodeOverviewTopic(params);
        ratesComponent = new TaxCodeRatesTopic(params);
    });
    it('should initialize TaxCodeOverviewTopic', () => {
        expect(overviewComponent).toBeTruthy();
    });
    it('should initialize TaxCodeRatesTopic', () => {
        expect(ratesComponent).toBeTruthy();
    });
});