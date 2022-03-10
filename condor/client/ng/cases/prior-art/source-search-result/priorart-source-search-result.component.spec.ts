import { StateServiceMock } from 'mocks';
import { ChangeDetectorRefMock } from 'mocks/change-detector-ref.mock';
import { IpxNotificationServiceMock, NotificationServiceMock } from 'mocks/notification-service.mock';
import { of } from 'rxjs';
import { PriorArtDetailsComponent } from '../priorart-details/priorart-details.component';
import { PriorartMaintenanceHelper } from '../priorart-maintenance/priorart-maintenance-helper';
import { PriorArtSearch } from '../priorart-search/priorart-search-model';
import { PriorArtServiceMock } from '../priorart.service.mock';
import { PriorartSourceSearchResultComponent } from './priorart-source-search-result.component';

describe('PriorartSourceSearchResultComponent', () => {
    let component: PriorartSourceSearchResultComponent;
    let notificationServiceMock: IpxNotificationServiceMock;
    let successNotificationServiceMock: NotificationServiceMock;
    let cdRef: ChangeDetectorRefMock;
    let stateService: any;
    const localDatePipe = { transform: jest.fn() };
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
        notificationServiceMock.openDiscardModal = jest.fn().mockReturnValue({ content: { confirmed$: of(true) } });
        cdRef = new ChangeDetectorRefMock();
        successNotificationServiceMock = new NotificationServiceMock();
        stateService = new StateServiceMock();
        component = new PriorartSourceSearchResultComponent(serviceMock as any, notificationServiceMock as any, successNotificationServiceMock as any, cdRef as any, { keys: { priorart: { search: { sourcePageSize: jest.fn() } } } } as any);
        component.searchData = data;
    });

    it('should create and initialise the modal', () => {
        component.ngOnInit();
        expect(component).toBeDefined();
        expect(component.gridOptions).toBeDefined();
    });

    it('should create required columns', () => {
        component.hidePriorArtStatus = true;
        component.ngOnInit();
        expect(component.gridOptions.columns.length).toBe(11);
    });

    describe('Citing the source document', () => {
        const dataItem = {
            abstract: 'abby stract',
            countryCode: 'AU',
            officialNumber: '777777',
            reference: 'ref',
            kind: 'BB',
            hasChanges: false
        };
        const priorArtSearch = new PriorArtSearch();
        priorArtSearch.caseKey = 555;
        priorArtSearch.sourceDocumentId = 5;
        priorArtSearch.officialNumber = '777777';
        priorArtSearch.country = 'AU';

        it('should cite the data when cite details', () => {
            component.searchData = priorArtSearch;
            component.ngOnInit();
            component.cite(dataItem);

            expect(serviceMock.citeSourceDocument$).toHaveBeenCalled();
        });
        it('displays success message', (done) => {
            component.searchData = priorArtSearch;
            component.ngOnInit();
            component.dataDetailComponent = new PriorArtDetailsComponent(serviceMock as any, cdRef as any, null, null, localDatePipe as any, stateService);
            component.dataDetailComponent.resetForm = jest.fn();
            component.cite(dataItem);
            serviceMock.citeSourceDocument$().subscribe(() => {
                expect(successNotificationServiceMock.success).toHaveBeenCalledWith('priorart.citedMessage');
                expect(component.dataDetailComponent.resetForm).toHaveBeenCalled();
                done();
            });
        });
    });

    describe('Collapsing the details', () => {
        it('should not display warning if no changes', () => {
            component.ngOnInit();
            component.onCollapse({ dataItem: { hasChanges: false } });
            expect(notificationServiceMock.openDiscardModal).not.toHaveBeenCalled();
        });
        it('displays discard confirmation', () => {
            const eventData = { dataItem: { hasChanges: true } };
            component.ngOnInit();
            component.onCollapse(eventData);
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