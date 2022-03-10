import { BehaviorSubject, Observable, of } from 'rxjs';

export class PriorArtServiceMock {
    hasPendingChanges$ = new BehaviorSubject(false);
    getPriorArtData$: (sourceId: Number, caseKey: Number) => Observable<any> = jest.fn();
    getSearchedData$ = jest.fn().mockReturnValue(of({}));
    getPriorArtTranslations$ = jest.fn().mockReturnValue(of({}));
    importCase$ = jest.fn().mockReturnValue(of({}));
    importIPOne$ = jest.fn().mockReturnValue(of({}));
    citeInprotechPriorArt$ = jest.fn().mockReturnValue(of({}));
    existingPriorArt$ = jest.fn().mockReturnValue(of({}));
    maintainPriorArt$ = jest.fn().mockReturnValue(of({ savedSuccessfully: true}));
    saveInprotechPriorArt$ = jest.fn().mockReturnValue(of({result: { result: 'success'}}));
    deletePriorArt$ = jest.fn().mockReturnValue(of({}));
    deleteCitation$ = jest.fn().mockReturnValue(of({}));
    formatDate = jest.fn();
    citeSourceDocument$ = jest.fn().mockReturnValue(of({}));
    getCitations$ = jest.fn();
    createLinkedCases$ = jest.fn().mockReturnValue(of({isSuccessful: true}));
    existingLiterature$ = jest.fn().mockReturnValue(of({}));
    createInprotechPriorArt$ = jest.fn().mockReturnValue(of({}));
    updatePriorArtStatus$ = jest.fn().mockReturnValue(of({}));
    removeLinkedCases$ = jest.fn().mockReturnValue(of({}));
    getFamilyCaseList$ = jest.fn().mockReturnValue(of({}));
    getLinkedNameList$ = jest.fn().mockReturnValue(of({}));
    removeAssociation$ = jest.fn().mockReturnValue(of({isSuccessful: true}));
    hasUpdatedAssociations$ = { next: jest.fn()};
    getFamilyCaseListDetails$ = jest.fn().mockReturnValue(of([]));
}

export class PriorArtShortcutsMock {
    registerHotkeysForSave = jest.fn();
    registerHotkeysForRevert = jest.fn();
    registerHotkeysForSearch = jest.fn();
}
