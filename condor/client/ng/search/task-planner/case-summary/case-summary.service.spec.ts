import { of } from 'rxjs';
import { CaseSummaryService } from './case-summary.service';

describe('Case Summary service', () => {
    let service: CaseSummaryService;
    let httpClientSpy;

    beforeEach(() => {
        httpClientSpy = { get: jest.fn(), post: jest.fn() };
        service = new CaseSummaryService(httpClientSpy);
    });

    describe('calling the api', () => {

        it('should exist', () => {
            expect(service).toBeDefined();
        });
        it('calls the service to retrieve case summary details', () => {
            const caseKey = 1234;
            const response = {
                caseData: {
                    caseKey: 123,
                    title: 'Abc'
                }
            };
            httpClientSpy.get.mockReturnValue(of(response));
            service.getCaseSummary(caseKey).subscribe(
                result => {
                    expect(result).toBeTruthy();
                }
            );
        });

        it('calls the service to retrieve task planner details', () => {
            const key = '1234^37ewe^4uew';
            const response = {
                delegationData: {
                    caseOffice: 'Office',
                    dueDateResponsibility: 'Abc'
                }
            };
            httpClientSpy.get.mockReturnValue(of(response));
            service.getTaskDetailsSummary(key).subscribe(
                result => {
                    expect(result).toBeTruthy();
                    expect(result).toBe(response);
                }
            );
        });

        it('calls the service to retrieve task details', () => {
            const key = 'C^123^xyz^';
            const response = {
                taskSummary: {
                    taskDetails: {},
                    delegationDetails: {}
                }
            };
            httpClientSpy.get.mockReturnValue(of(response));
            service.getTaskDetailsSummary(key).subscribe(
                result => {
                    expect(result).toBeTruthy();
                }
            );
        });
    });
});
