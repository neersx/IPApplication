import { Observable } from 'rxjs';

export class CaseSearchServiceMock {
    caseSearchData = {
        viewData: {
            canCreateSavedSearch: false,
            canUpdateSavedSearch: false,
            canMaintainPublicSearch: false,
            canDeleteSavedSearch: false
        }
    };
    applySanityCheck = jest.fn().mockReturnValue(new Observable());
}