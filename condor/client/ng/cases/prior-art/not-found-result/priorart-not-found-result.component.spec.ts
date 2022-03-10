import { fakeAsync, tick } from '@angular/core/testing';
import { LocalSettingsMock } from 'core/local-settings.mock';
import { IpxNotificationServiceMock, NotificationServiceMock } from 'mocks';
import { of } from 'rxjs/internal/observable/of';
import { IpxKendoGridComponentMock } from 'shared/component/grid/ipx-kendo-grid.component.mock';
import { PriorArtDetailsComponent } from '../priorart-details/priorart-details.component';
import { PriorartNotFoundResultComponent } from './priorart-not-found-result.component';

describe('PriorartSearchResultComponent', () => {
    let component: PriorartNotFoundResultComponent;
    let notificationService: any;
    let successNotification: any;
    let localSettings: any;
    const data: any = {
        result: [{
            errors: false,
            matches: [{
                id: 1
            },
            {
                id: 2
            }],
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
            }],
            message: 'ccc',
            source: 'ExistingPriorArtFinder'
        }]
    };

    beforeEach(() => {
        notificationService = new IpxNotificationServiceMock();
        successNotification = new NotificationServiceMock();
        notificationService.modalRef.content = {
            confirmed$: of('confirm'), cancelled$: of()
        };
        localSettings = new LocalSettingsMock();
        component = new PriorartNotFoundResultComponent(notificationService, successNotification, localSettings);
        component.data = data;
        component.ngOnInit();
        component.grid = {search: jest.fn(), wrapper: {wrapper: {nativeElement: { querySelector: jest.fn() }}}} as any;
    });

    it('should create and initialise the component', () => {
        expect(component).toBeDefined();
        expect(component.gridOptions).toBeDefined();
    });

    describe('onSaveData', () => {
        it('should show succesfull save when saved succesfully', () => {
            const event = {
                success: true
            };
            component.onSaveData(event);
            expect(successNotification.success).toHaveBeenCalled();
            expect(component.grid.search).toHaveBeenCalled();
        });
    });
    describe('Collapsing the details', () => {
        it('should not display warning if no changes', () => {
            component.onCollapse({ dataItem: { hasChanges: false } });
            expect(notificationService.openDiscardModal).not.toHaveBeenCalled();
        });
        it('displays discard confirmation', fakeAsync(() => {
            component.dataDetailComponent = {revertForm: jest.fn()} as any;
            component.onCollapse({ dataItem: { hasChanges: true } });
            expect(notificationService.openDiscardModal).toHaveBeenCalled();
            tick();
            expect(component.dataDetailComponent.revertForm).toHaveBeenCalled();
        }));
    });
});