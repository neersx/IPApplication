import { CaseDetailServiceMock } from 'cases/case-view/case-detail.service.mock';
import { CaseWebLinksTaskProvider } from './case-web-links-task-provider';

describe('CaseWebLinksTaskProvider', () => {
    let service: CaseWebLinksTaskProvider;
    const caseDetailService = new CaseDetailServiceMock();

    beforeEach(() => {
        service = new CaseWebLinksTaskProvider(
            caseDetailService as any
        );
    });
    it('should load case web links service', () => {
        expect(service).toBeTruthy();
    });

    it('should call caseDetailsService weblinks', () => {
        const dataItem = { caseKey: 1 };
        service.subscribeCaseWebLinks(dataItem, null);
        expect(caseDetailService.getCaseWebLinks$).toHaveBeenCalledWith(1);
    });

});