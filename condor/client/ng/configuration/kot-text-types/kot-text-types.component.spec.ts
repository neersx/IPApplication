import { ModalServiceMock } from 'mocks/modal-service.mock';
import { NotificationServiceMock } from 'mocks/notification-service.mock';
import { BehaviorSubject } from 'rxjs';
import { KotMaintainConfigComponent } from './kot-maintain-config/kot-maintain-config.component';
import { KotTextTypesComponent } from './kot-text-types.component';
import { KotFilterTypeEnum } from './kot-text-types.model';
import { KotTextTypesServiceMock } from './kot-text-types.service.mock';

describe('Inprotech.Configuration.KotTextTypes', () => {
    let component: () => KotTextTypesComponent;
    let service: KotTextTypesServiceMock;
    let modalService: ModalServiceMock;
    let transitionService: any;
    let notificationService: NotificationServiceMock;

    beforeEach(() => {
        service = new KotTextTypesServiceMock();
        modalService = new ModalServiceMock();
        notificationService = new NotificationServiceMock();

        component = () => {
            const c = new KotTextTypesComponent(service as any, transitionService, modalService as any, notificationService as any);
            c.ngOnInit();

            return c;
        };
    });

    it('should initialise', () => {
        transitionService = { params: jest.fn().mockReturnValue({ filterBy: KotFilterTypeEnum.byCase }) };
        const c = component();
        spyOn(c, 'buildGridOptions');

        expect(c.gridOptions).toBeDefined();
        expect(c.gridOptions.columns.length).toBe(6);
        expect(c.gridOptions.columns[0].title).toBe('kotTextTypes.column.nameType');
        expect(c.gridOptions.columns[0].field).toBe('nameTypes');
    });

    it('should set gridOptions.columns based of filterType c', () => {
        const c = component();
        c.gridOptions._search = jest.fn();
        c.changeFilterBy(KotFilterTypeEnum.byCase);
        expect(c.gridOptions.columns[0].title).toEqual('kotTextTypes.column.caseType');
        expect(c.gridOptions.columns[0].field).toEqual('caseTypes');
    });

    it('should set gridOptions.columns based of filterType n', () => {
        const c = component();
        c.gridOptions._search = jest.fn();
        c.changeFilterBy(KotFilterTypeEnum.byName);
        expect(c.gridOptions.columns[0].title).toEqual('kotTextTypes.column.nameType');
        expect(c.gridOptions.columns[0].field).toEqual('nameTypes');
        expect(c.gridOptions._search).toHaveBeenCalled();
    });

    it('should set setBackgroundColor based of type color type', () => {
        const c = component();
        const color = c.setBackgroundColor('#000f');
        expect(color).toEqual(
            {
                'background-color': '#000f',
                display: 'block'
            }
        );
    });

    it('should set setBackgroundColor to while when color type is null', () => {
        const c = component();
        const color = c.setBackgroundColor(null);
        expect(color).toEqual(
            {
                'background-color': '#ffff',
                display: 'block'
            }
        );
    });

    it('should handle row add edit correctly', () => {
        const c = component();
        modalService.openModal.mockReturnValue({
            content: {
                onClose$: new BehaviorSubject(true),
                addedRecordId$: new BehaviorSubject(0)
            }
        });

        const data = {};
        c.onRowAddedOrEdited(data as any, 'Add');
        expect(modalService.openModal).toHaveBeenCalledWith(KotMaintainConfigComponent,
            {
                animated: false,
                backdrop: 'static',
                class: 'modal-lg',
                initialState: {
                    state: 'Add',
                    entryId: null,
                    filterBy: KotFilterTypeEnum.byName
                }
            });
    });

    it('should handle row duplicate correctly', () => {
        const c = component();
        modalService.openModal.mockReturnValue({
            content: {
                onClose$: new BehaviorSubject(true),
                addedRecordId$: new BehaviorSubject(0)
            }
        });

        const data = { dataItem: { id: 1 } };
        c.onRowAddedOrEdited(data as any, 'Duplicate');
        expect(modalService.openModal).toHaveBeenCalledWith(KotMaintainConfigComponent,
            {
                animated: false,
                backdrop: 'static',
                class: 'modal-lg',
                initialState: {
                    state: 'Duplicate',
                    entryId: 1,
                    filterBy: KotFilterTypeEnum.byName
                }
            });
    });
    it('should show delete confirmation', () => {
        const c = component();
        const data = { id: 1 };
        c.onRowDeleted(data as any);
        expect(notificationService.confirmDelete).toHaveBeenCalledWith({
            message: 'picklistmodal.confirm.delete'
        });
    });
    it('should show call service delete', () => {
        transitionService = { params: jest.fn().mockReturnValue({ filterBy: KotFilterTypeEnum.byName }) };
        const c = component();
        c.deleteKot(1);
        expect(service.deleteKotTextType).toBeCalledWith(1, KotFilterTypeEnum.byName);
    });
    describe('Filter search Kot', () => {
        it('should call search grid on search click', () => {
            const c = component();
            c.gridOptions._search = jest.fn();
            c.filterCriteria = { type: KotFilterTypeEnum.byCase };
            c.modules = [{ key: 1, name: 'abc' }];
            c.status = [{ key: 11, name: 'xyz' }];
            c.search();
            expect(c.filterCriteria.modules).toEqual(['abc']);
            expect(c.filterCriteria.statuses).toEqual(['xyz']);
            expect(c.filterCriteria.roles).toBe(null);
            expect(c.gridOptions._search).toBeCalled();
        });

        it('should clear default values of filter', () => {
            const c = component();
            c.gridOptions._search = jest.fn();
            c.clear();
            expect(c.modules).toBe(null);
            expect(c.status).toBe(null);
            expect(c.roles).toBe(null);
            expect(c.gridOptions._search).toBeCalled();
        });
    });
});