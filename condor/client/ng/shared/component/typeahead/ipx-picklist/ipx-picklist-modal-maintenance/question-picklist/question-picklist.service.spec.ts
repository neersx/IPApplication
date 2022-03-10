import { fakeAsync, tick } from '@angular/core/testing';
import { HttpClientMock } from 'mocks';
import { IpxQuestionPicklistService } from './question-picklist.service';

describe('Service: QuestionPicklist', () => {
    let http: any;
    let service: IpxQuestionPicklistService;
    beforeEach(() => {
        http = new HttpClientMock();
        service = new IpxQuestionPicklistService(http);
    });
    it('should create an instance', () => {
        expect(service).toBeTruthy();
    });
    it('should set the view data', fakeAsync(() => {
        service.getViewData();
        tick(10);
        expect(http.get).toHaveBeenCalledWith('api/picklists/questions/view');
        expect(service.viewData$).toBeDefined();
    }));
});
