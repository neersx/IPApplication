import { async } from '@angular/core/testing';
import { NgForm } from '@angular/forms';
import { BsModalRefMock, ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock, SearchPresentationServiceMock, StateServiceMock } from 'mocks';
import { KeyBoardShortCutServiceMock } from 'mocks/keyboardshortcutservice.mock';
import { Observable } from 'rxjs';
import { SearchTypeConfigProvider } from '../common/search-type-config.provider';
import { SavedSearchComponent } from './saved-search.component';

describe('Saved Search component', () => {
    let c: SavedSearchComponent;
    const notificationService = new NotificationServiceMock();
    const ipxNotificationService = new IpxNotificationServiceMock();
    const stateMock = new StateServiceMock();
    const bsModalRefMock = new BsModalRefMock();
    const service = { saveSearch: jest.fn().mockReturnValue(new Observable()), getDetails$: jest.fn().mockReturnValue(new Observable()) };
    const keyBoardShortCutServiceMock = new KeyBoardShortCutServiceMock();
    let cdRef: ChangeDetectorRefMock;
    const searchPresentationService = new SearchPresentationServiceMock();
    beforeEach(() => {
        cdRef = new ChangeDetectorRefMock();
        c = new SavedSearchComponent(bsModalRefMock, notificationService as any,
            service as any, stateMock as any, keyBoardShortCutServiceMock as any,
            ipxNotificationService as any, cdRef as any, searchPresentationService as any);
        SearchTypeConfigProvider.savedConfig = { baseApiRoute: 'api/search/case/' } as any;
        c.formData = {
            searchName: '',
            description: '',
            public: false
        };
        c.ngForm = new NgForm(null, null);
        c.filter = {};
    });

    it('should create the component instance', async(() => {
        expect(c).toBeTruthy();
    }));

    it('should close the modalref', async(() => {
        spyOn(bsModalRefMock, 'hide');
        c.close();
        expect(bsModalRefMock.hide).toBeCalled();
    }));

    it('should call save search', async(() => {
        c.updatePresentation = false;
        c.queryKey = 35;
        c.formData.searchName = 'searc new name saved';
        c.formData.public = true;

        const saveSearchEntity = {
            id: 35,
            searchName: c.formData.searchName,
            description: c.formData.description,
            groupKey: null,
            isPublic: c.formData.public,
            searchFilter: c.filter,
            selectedColumns: c.selectedColumns,
            updatePresentation: c.updatePresentation
        };

        jest.spyOn(service, 'saveSearch');
        jest.spyOn(service, 'getDetails$').mockReturnValue(c.formData);
        jest.spyOn(c, 'saveSearchEntity');
        c.ngOnInit();
        c.saveSearch();
        expect(c.saveSearchEntity).toBeCalled();
        expect(c.type).not.toBeNull();

        expect(service.saveSearch).toBeCalledWith(saveSearchEntity, c.type, c.queryKey, SearchTypeConfigProvider.savedConfig);
    }));

    it('should OnInit', async(() => {
        c.queryContextKey = 970;
        c.type = 0;
        c.ngOnInit();
        expect(c.isCaseSearchSave).toEqual(false);
        c.queryContextKey = 2;
        c.type = 0;
        c.ngOnInit();
        expect(c.isCaseSearchSave).toEqual(true);
    }));

});