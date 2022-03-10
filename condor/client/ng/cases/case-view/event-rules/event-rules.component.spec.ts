import { BsModalRefMock, ChangeDetectorRefMock, GridNavigationServiceMock } from 'mocks';
import { of } from 'rxjs';
import { EventRulesComponent } from './event-rules.component';

describe('EventRulesComponent', () => {

    let component: EventRulesComponent;
    let bsModafRefMock: BsModalRefMock;
    let serviceMock: { get: jest.Mock, getEventDetails$: jest.Mock, createItemKeyMappings: jest.Mock };
    let changeDetectorMock: ChangeDetectorRefMock;
    let gridNavigationService: GridNavigationServiceMock;

    beforeEach(() => {
        bsModafRefMock = new BsModalRefMock();
        changeDetectorMock = new ChangeDetectorRefMock();
        serviceMock = { get: jest.fn().mockReturnValue(of()), getEventDetails$: jest.fn().mockReturnValue(of()), createItemKeyMappings: jest.fn().mockReturnValue(of()) };
        gridNavigationService = new GridNavigationServiceMock();
        component = new EventRulesComponent(bsModafRefMock as any, serviceMock as any, changeDetectorMock as any, gridNavigationService as any);
        component.eventRulesRequest = {
            eventNo: -133,
            caseId: 100,
            cycle: 1,
            action: 'AC'
        };
        component.eventNo = -133;
        component.navData = {
            keys: [{ key: '1', value: '-134' }, { key: '2', value: '21' }, { key: '3', value: '-133' }, { key: '4', value: '51' }],
            totalRows: 4,
            pageSize: 0,
            fetchCallback: jest.fn()
        };
        component.q = {
            criteria: {
                caseKey: 100,
                cycle: 1,
                actionId: 'AC',
                criteriaId: 1
            },
            params: {
                skip: 0,
                take: 10
            }
        };
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });

    it('should default the date format and the context from the date service', () => {
        jest.spyOn(serviceMock, 'createItemKeyMappings').mockReturnValue(component.navData.keys);
        jest.spyOn(gridNavigationService, 'getNavigationData').mockReturnValue(component.navData);
        component.ngOnInit();
        serviceMock.getEventDetails$().subscribe(() => {
            expect(component.eventRuleDetails).toBeDefined();
            expect(changeDetectorMock.markForCheck).toHaveBeenCalled();
        });
    });

    it('should get current key', () => {
        jest.spyOn(serviceMock, 'createItemKeyMappings').mockReturnValue(component.navData.keys);
        jest.spyOn(gridNavigationService, 'getNavigationData').mockReturnValue(component.navData);
        component.ngOnInit();
        expect(component.currentKey).toEqual('3');
    });

    it('should close the modal', () => {
        jest.spyOn(component.modalRef, 'hide');
        component.onClose();
        expect(component.modalRef.hide).toBeCalled();
    });

});