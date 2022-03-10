import { ICaseSummaryService } from './case-summary.service';

export class CaseSummaryServiceMock implements ICaseSummaryService {
    getCaseSummary = jest.fn();
    getCaseFinancials = jest.fn();
    getTaskDetailsSummary = jest.fn();
}