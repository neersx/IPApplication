import { TranslationServiceMock } from 'ajs-upgraded-providers/mocks/translation-service.mock';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock, IpxGridOptionsMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { ChecklistSearchComponent } from './checklist-search.component';

describe('ChecklistConfigurationComponent', () => {
    let component: ChecklistSearchComponent;
    let cdRef: any;
    let service: any;
    let localSettings: any;
    let translateService: any;
    let modalService: any;

    beforeEach(() => {
        cdRef = new ChangeDetectorRefMock();
        service = {};
        localSettings = new LocalSettingsMock();
        translateService = new TranslationServiceMock();
        modalService = new ModalServiceMock();
        component = new ChecklistSearchComponent(cdRef, service, localSettings, translateService, modalService);
        component.viewData = {
            canMaintainProtectedRules: true,
            canMaintainRules: true,
            canMaintainQuestion: true,
            hasOffices: true,
            canAddProtectedRules: true,
            canAddRules: true
        };
        component.searchResultsGrid = { dataOptions: { gridMessages: {} } as any, search: jest.fn(), clearFilters: jest.fn() } as any;
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    describe('ngOnInit', () => {

        it('should call change detection on init and default settings to correct values', () => {
            component.ngOnInit();
            component.ngAfterViewInit();
            expect(component.matchType).toEqual('characteristic');
            expect(cdRef.detectChanges).toHaveBeenCalled();
            expect(component.searchGridOptions).toBeDefined();
        });
    });

    describe('searching', () => {
        it('sets the criteria and calls the search', () => {
            component.ngOnInit();
            const filter = { caseType: 'ABC', checklist: '555' };
            component.search(filter);
            expect(component.criteria).toBe(filter);
            expect(component.searchResultsGrid.search).toHaveBeenCalled();
            expect(component.searchResultsGrid.dataOptions.gridMessages.noResultsFound).toBe('noResultsFound');
        });
        it('sets the correct message when searching exact-match and is missing checklist type', () => {
            component.ngOnInit();
            const filter = { caseType: 'XYZ', matchType: 'exact-match' };
            component.search(filter);
            expect(component.criteria).toBe(filter);
            expect(component.searchResultsGrid.search).toHaveBeenCalled();
            expect(component.searchResultsGrid.dataOptions.gridMessages.noResultsFound).toBe('noResultsFound');
        });
        it('sets the correct message when not searching exact-match and is missing checklist type', () => {
            component.ngOnInit();
            const filter = { caseType: 'XYZ', matchType: 'other-search' } ;
            component.search(filter);
            expect(component.criteria).toBe(filter);
            expect(component.searchResultsGrid.search).toHaveBeenCalled();
            expect(component.searchResultsGrid.dataOptions.gridMessages.noResultsFound).not.toBe('noResultsFound');
        });
    });
});
