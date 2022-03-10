import { BillingStepsPersistanceService } from 'accounting/billing/billing-steps-persistance.service';
import { BillingServiceMock } from 'accounting/billing/billing.mocks';
import { ChangeDetectorRefMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { DebtorCopiesToNamesGridComponent } from './debtor-copies-to-grid.component';
import { MaintainDebtorCopiesToComponent } from './maintain-debtor-copies-to.component';

describe('DebtorCopiesToGridComponent', () => {
    let component: DebtorCopiesToNamesGridComponent;
    let modalService: ModalServiceMock;
    let service: BillingServiceMock;
    let stepsService: BillingStepsPersistanceService;
    let cdRef: ChangeDetectorRefMock;
    beforeEach(() => {
        service = new BillingServiceMock();
        modalService = new ModalServiceMock();
        stepsService = new BillingStepsPersistanceService();
        cdRef = new ChangeDetectorRefMock();
        component = new DebtorCopiesToNamesGridComponent(modalService as any, stepsService as any, cdRef as any, service as any);
        component.grid = {
            checkChanges: jest.fn(),
            isValid: jest.fn(),
            isDirty: jest.fn(),
            search: jest.fn(),
            removeRow: jest.fn(),
            wrapper: {
                closeRow: jest.fn(),
                data: [
                    {
                        CopyToNameId: 123
                    }, {
                        CopyToNameId: 456
                    }
                ]
            }
        } as any;
        component.debtorNameId = 1;
        component.gridOptions = { maintainFormGroup$: { next: jest.fn() } } as any;
        component.reasonList = [{ Id: 1, Name: 'Reason 1' }, { Id: 2, Name: 'Reason 2' }];
        component.copiesTo = [{ CopyToNameId: 123, AddressChangeReasonId: 1 }, { CopyToNameId: 456, AddressChangeReasonId: null }];
    });
    it('should create', () => {
        expect(component).toBeTruthy();
    });
    it('should set reason description', () => {
        component.ngOnInit();
        expect(component.copiesTo[0].AddressChangeReason).toBe('Reason 1');
        expect(component.copiesTo[1].AddressChangeReason).toBe(undefined);
    });
    it('should open modal on add/ edit', () => {
        const data = { dataItem: { status: rowStatus.Adding }, rowIndex: 1 };
        component.onRowAddedOrEdited(data);
        expect(modalService.openModal).toBeCalledWith(MaintainDebtorCopiesToComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-lg',
            initialState: {
                isAdding: data.dataItem.status === rowStatus.Adding,
                grid: component.grid,
                dataItem: data.dataItem,
                debtorNameId: component.debtorNameId,
                rowIndex: data.rowIndex,
                reasonList: component.reasonList
            }
        });
    });
    it('should call maintainFormGroup and updatePersistence Service if copies to name is added or edited', () => {
        component.updatePersistanceService = jest.fn();
        const data = { dataItem: { status: rowStatus.Adding }, rowIndex: 1 };
        const event = { formGroup: {}, success: true };
        component.onCloseModal(event, data);
        expect(component.gridOptions.maintainFormGroup$.next).toHaveBeenCalled();
        expect(component.copiesTo[0].AddressChangeReason).toBe('Reason 1');
        expect(component.updatePersistanceService).toBeCalled();
    });
    it('should call remove added row when cancel is clicked on modal', () => {
        const data = { dataItem: { status: rowStatus.Adding }, rowIndex: 1 };
        const event = { formGroup: {}, success: false };
        component.grid.wrapper.data = [{ copyToNameId: 1 }, undefined];
        component.onCloseModal(event, data);
        expect(component.grid.removeRow).toBeCalledWith(1);
    });
    it('should update persistence service step data for copies to', () => {
        stepsService.billingSteps = [{ id: 1, selected: true, stepData: { debtorData: [{ NameId: 1 }] }, isDefault: true, title: 'Step 1' }];
        service.copiesToCount$.next = jest.fn();
        component.updatePersistanceService();
        expect(stepsService.billingSteps[0].stepData.debtorData[0].copiesTo.length).toBe(2);
        expect(service.copiesToCount$.next).toBeCalledWith({
            debtorNameId: 1,
            count: 2
        });
    });
});