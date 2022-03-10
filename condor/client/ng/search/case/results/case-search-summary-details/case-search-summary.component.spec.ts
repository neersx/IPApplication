import { HttpClientMock } from 'mocks';
import { of } from 'rxjs';
import { CaseSearchService } from 'search/case/case-search.service';

import { IpxCaseSearchSummaryComponent } from './case-search-summary.component';

describe('CaseSearchSummaryComponent', () => {
    let component: IpxCaseSearchSummaryComponent;
    let caseSearchService: CaseSearchService;

    beforeEach(() => {
        caseSearchService = new CaseSearchService(HttpClientMock as any, {} as any);
        component = new IpxCaseSearchSummaryComponent(caseSearchService, {} as any, {} as any);
    });

    describe('loading the data', () => {
        it('calls the service to retrieve case summary details', () => {
            const caseSummarySpy = spyOn(caseSearchService, 'getCaseSummary').and.returnValue(of());
            component.caseKey = 1234;
            caseSearchService.rowSelected.next(component.caseKey);
            // tslint:disable-next-line: no-unbound-method
            caseSearchService.rowSelected.subscribe(() => {
                expect(caseSummarySpy).toHaveBeenCalledWith(1234);
            });
        });
    });
});
