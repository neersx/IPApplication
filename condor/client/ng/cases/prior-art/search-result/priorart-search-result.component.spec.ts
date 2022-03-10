import { LocalSettingsMock } from 'core/local-settings.mock';
import { ChangeDetectorRefMock } from 'mocks/change-detector-ref.mock';
import { IpxNotificationServiceMock, NotificationServiceMock } from 'mocks/notification-service.mock';
import { of } from 'rxjs';
import { PriorartMaintenanceHelper } from '../priorart-maintenance/priorart-maintenance-helper';
import { PriorArtSearch } from '../priorart-search/priorart-search-model';
import { PriorArtServiceMock } from '../priorart.service.mock';
import { PriorartSearchResultComponent } from './priorart-search-result.component';

describe('PriorartSearchResultComponent', () => {
    let component: PriorartSearchResultComponent;
    let notificationServiceMock: IpxNotificationServiceMock;
    let successNotificationServiceMock: NotificationServiceMock;
    let cdRef: ChangeDetectorRefMock;
    let localSettings: any;
    const serviceMock = new PriorArtServiceMock();
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
                id: 1
            },
            {
                id: 2
            },
            {
                id: 3
            }
            ],
            message: 'ccc',
            source: 'ExistingPriorArtFinder'
        }
        ]
    };

    beforeEach(() => {
        notificationServiceMock = new IpxNotificationServiceMock();
        cdRef = new ChangeDetectorRefMock();
        successNotificationServiceMock = new NotificationServiceMock();
        localSettings = new LocalSettingsMock();
        component = new PriorartSearchResultComponent(serviceMock as any, notificationServiceMock as any, successNotificationServiceMock as any, cdRef as any, localSettings);
        component.data = data;
    });

    it('should create and initialise the modal', () => {
        component.ngOnInit();
        expect(component).toBeDefined();
        expect(component.gridOptions).toBeDefined();
    });

    it('should create required columns', () => {
        component.hidePriorArtStatus = true;
        component.ngOnInit();
        expect(component.gridOptions.columns.length).toBe(7);

        component.hidePriorArtStatus = false;
        component.ngOnInit();
        expect(component.gridOptions.columns.length).toBe(8);
    });

    it('should import the data when import basic details', () => {
        const dataItem = {
            abstract: 'abby stract',
            countryCode: 'AU',
            officialNumber: '777777',
            reference: 'ref',
            kind: 'BB'
        };
        const priorArtSearch = new PriorArtSearch();
        priorArtSearch.caseKey = 555;
        priorArtSearch.officialNumber = '77777';
        priorArtSearch.country = 'AU';
        serviceMock.existingPriorArt$.mockReturnValue(of({
            result: false
        }));
        component.searchData = priorArtSearch;
        component.ngOnInit();
        component.import(dataItem);

        expect(serviceMock.existingPriorArt$).toHaveBeenCalledWith(dataItem.countryCode, dataItem.reference, dataItem.kind);
        expect(serviceMock.importIPOne$).toHaveBeenCalled();
        expect(serviceMock.importIPOne$.mock.calls[0][0].evidence).toEqual(expect.objectContaining({
            abstract: 'abby stract',
            countryCode: 'AU',
            officialNumber: '777777',
            reference: 'ref',
            kind: 'BB',
            applicationDate: null,
            publishedDate: null,
            grantedDate: null,
            priorityDate: null,
            ptoCitedDate: null
        }));
    });

    it('should ask for user to proceed when prior already exists while importing', () => {
        const dataItem = {
            abstract: 'abby stract',
            countryCode: 'AU',
            officialNumber: '777777',
            reference: 'ref',
            kind: 'BB'
        };
        const priorArtSearch = new PriorArtSearch();
        priorArtSearch.caseKey = 555;
        priorArtSearch.officialNumber = '77777';
        priorArtSearch.country = 'AU';
        serviceMock.existingPriorArt$.mockReturnValue(of({
            result: true
        }));
        component.searchData = priorArtSearch;
        component.ngOnInit();
        component.import(dataItem);

        expect(notificationServiceMock.openConfirmationModal).toHaveBeenCalled();
    });

    it('should cite the data when cite details', () => {
        const dataItem = {
            abstract: 'abby stract',
            countryCode: 'AU',
            officialNumber: '777777',
            reference: 'ref',
            kind: 'BB'
        };
        const priorArtSearch = new PriorArtSearch();
        priorArtSearch.caseKey = 555;
        priorArtSearch.sourceDocumentId = 5;
        priorArtSearch.officialNumber = '77777';
        priorArtSearch.country = 'AU';
        component.searchData = priorArtSearch;
        component.ngOnInit();
        component.cite(dataItem);

        expect(serviceMock.citeInprotechPriorArt$).toHaveBeenCalled();
    });

    describe('Collapsing the details', () => {
        it('should not display warning if no changes', () => {
            component.onCollapse({ dataItem: { hasChanges: false } });
            expect(notificationServiceMock.openDiscardModal).not.toHaveBeenCalled();
        });
        it('displays discard confirmation', () => {
            component.onCollapse({ dataItem: { hasChanges: true } });
            expect(notificationServiceMock.openDiscardModal).toHaveBeenCalled();
        });
    });

    describe('Edit', () => {
        it('should call the maintenance helper', () => {
            spyOn(PriorartMaintenanceHelper, 'openMaintenance');
            component.searchData = { ...new PriorArtSearch(), ...{ caseKey: 9902 } };
            component.edit({ sourceId: 5678 });
            expect(PriorartMaintenanceHelper.openMaintenance).toHaveBeenCalledWith({ sourceId: 5678 }, 9902);
        });
    });
});