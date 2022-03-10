import { HttpClientMock } from 'mocks';
import { KeepOnTopNotesViewService, KotViewForEnum, KotViewProgramEnum } from './keep-on-top-notes-view.service';

describe('RightBarNavLoaderService', () => {
    let service: KeepOnTopNotesViewService;
    let http: HttpClientMock;
    beforeEach(() => {
        http = new HttpClientMock();
        service = new KeepOnTopNotesViewService(http as any);
    });

    it('should create service instance', () => {
        expect(service).toBeTruthy();
    });

    it('should call service with correct params', () => {
        service.getKotForCaseView('123', KotViewProgramEnum.Case, KotViewForEnum.Case);
        expect(http.get).toBeCalledWith('api/keepontopnotes/123/Case');
        service.getKotForCaseView('123', KotViewProgramEnum.Time, KotViewForEnum.Name);
        expect(http.get).toBeCalledWith('api/keepontopnotes/name/123/Time');
    });
});