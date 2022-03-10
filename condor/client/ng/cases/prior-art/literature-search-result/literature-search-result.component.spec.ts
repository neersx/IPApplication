import { fakeAsync, tick } from '@angular/core/testing';
import { EMPTY_CELL_CONTEXT } from '@progress/kendo-angular-grid';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock, IpxNotificationServiceMock, NotificationServiceMock, TranslateServiceMock } from 'mocks';
import { of } from 'rxjs';
import { PriorartMaintenanceHelper } from '../priorart-maintenance/priorart-maintenance-helper';
import { PriorArtSearch } from '../priorart-search/priorart-search-model';
import { PriorArtServiceMock } from '../priorart.service.mock';
import { LiteratureSearchResultComponent } from './literature-search-result.component';

describe('LiteratureSearchResultComponent', () => {
    let component: LiteratureSearchResultComponent;
    let notificationServiceMock: any;
    let successNotificationServiceMock: any;
    let cdRef: any;
    let localSettings: any;
    let translateService: any;
    let serviceMock: any;
    const data: any = {
        result: [{
            errors: false,
            matches: [{
                id: 1
            },
            {
                id: 2
            }
            ],
            message: 'aaa',
            source: 'IpOneDataDocumentFinder'
        },
        {
            errors: false,
            matches: [{
                id: 1
            }],
            message: 'bbb',
            source: 'CaseEvidenceFinder'
        },
        {
            errors: false,
            matches: [{
                id: 1,
                publishedDate: '2000-01-01T00:00:00'
            },
            {
                id: 2,
                publishedDate: '2000-01-02T00:00:00'
            },
            {
                id: 3,
                publishedDate: '2000-01-03T00:00:00'
            }
            ],
            message: 'ccc',
            source: 'ExistingPriorArtFinder'
        }
        ]
    };

    beforeEach(() => {
        serviceMock = new PriorArtServiceMock();
        notificationServiceMock = new IpxNotificationServiceMock();
        successNotificationServiceMock = new NotificationServiceMock();
        cdRef = new ChangeDetectorRefMock();
        localSettings = new LocalSettingsMock();
        translateService = new TranslateServiceMock();
        component = new LiteratureSearchResultComponent(serviceMock, notificationServiceMock, successNotificationServiceMock, cdRef, localSettings, translateService);
        serviceMock.getSearchedData$ = jest.fn().mockReturnValue(of(data));
        component.searchData = new PriorArtSearch();
        document.querySelector = jest.fn().mockReturnValue({ scrollIntoView: jest.fn() });
        component.dataDetailComponent = {revertForm: jest.fn(), resetForm: jest.fn()} as any;
        component.grid = { search: jest.fn(), wrapper: { wrapper: { nativeElement: { querySelector: jest.fn() } } } } as any;
        notificationServiceMock.openDiscardModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true) } });
    });

    it('should create and initialise', () => {
        component.ngOnInit();
        expect(component).toBeTruthy();
    });
    it('should create required columns', () => {
        component.enableCiting = true;
        component.ngOnInit();
        expect(component.gridOptions.columns.length).toBe(8);

        component.enableCiting = false;
        component.ngOnInit();
        expect(component.gridOptions.columns.length).toBe(7);
    });

    describe('cite', () => {
        it('should cite the source when cite button is clicked', () => {
            const priorArtSearch = new PriorArtSearch();
            priorArtSearch.caseKey = 555;
            priorArtSearch.sourceDocumentId = 5;
            component.searchData = priorArtSearch;
            component.cite({
                id: 222
            });

            expect(serviceMock.citeInprotechPriorArt$).toHaveBeenCalledWith({ sourceDocumentId: priorArtSearch.sourceDocumentId, id: 222 }, priorArtSearch.caseKey);
        });
        it('should display confirmation if there are pending changes', fakeAsync(() => {
            notificationServiceMock.openDiscardModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true) } , hide: jest.fn()});
            const priorArtSearch = new PriorArtSearch();
            priorArtSearch.caseKey = 555;
            priorArtSearch.sourceDocumentId = 5;
            component.searchData = priorArtSearch;
            component.cite({
                id: 333,
                hasChanges: true
            });

            expect(notificationServiceMock.openDiscardModal).toHaveBeenCalled();
            tick();
            expect(serviceMock.citeInprotechPriorArt$).toHaveBeenCalledWith({sourceDocumentId: priorArtSearch.sourceDocumentId, id: 333}, priorArtSearch.caseKey);
        }));
    });

    describe('onSaveData', () => {
        it('should show succesfull save when saved succesfully', () => {
            const event = {
                success: true
            };
            component.onSaveData(event);

            expect(successNotificationServiceMock.success).toHaveBeenCalled();
            expect(component.showAddNewLiterature).toBeFalsy();
        });
    });

    it('adding literature displays the entry form', fakeAsync(() => {
        component.addLiterature();
        expect(component.showAddNewLiterature).toBeTruthy();
        expect(cdRef.detectChanges).toHaveBeenCalled();
        tick(100);
    }));

    describe('Collapsing the details', () => {
        it('should not display warning if no changes', () => {
            component.onCollapse({ dataItem: { hasChanges: false } });
            expect(notificationServiceMock.openDiscardModal).not.toHaveBeenCalled();
        });
        it('displays discard confirmation', fakeAsync(() => {
            component.onCollapse({ dataItem: { hasChanges: true } });
            expect(notificationServiceMock.openDiscardModal).toHaveBeenCalled();
            tick();
            expect(component.dataDetailComponent.revertForm).toHaveBeenCalled();
        }));
    });

    describe('Edit', () => {
        it('should call the maintenance helper', () => {
            spyOn(PriorartMaintenanceHelper, 'openMaintenance');
            component.searchData = { ...new PriorArtSearch(), ...{ caseKey: 9901 }};
            component.edit({sourceId: 1234});
            expect(PriorartMaintenanceHelper.openMaintenance).toHaveBeenCalledWith({sourceId: 1234}, 9901);
        });
    });
});
