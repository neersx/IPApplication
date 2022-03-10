import { NamesSummaryPaneService } from './names-summary-pane.service';

describe('NamesSummaryPaneService', () => {
    'use strict';

    let service: NamesSummaryPaneService;
    let httpClientSpy;

    beforeEach(() => {
        httpClientSpy = { get: jest.fn().mockReturnValue({toPromise: jest.fn().mockReturnValue({then: jest.fn}) })};
        service = new NamesSummaryPaneService(httpClientSpy);
    });

    describe('getName', () => {
        it('should pass correct parameters in api request', () => {
            service.getName(12345);
            expect(httpClientSpy.get).toHaveBeenCalledWith('api/picklists/names/12345');
        });
    });

});