import { LocalSettingsMock } from 'core/local-settings.mock';
import { BsModalRefMock, ChangeDetectorRefMock } from 'mocks';
import { ModalServiceMock } from 'mocks/modal-service.mock';
import { of } from 'rxjs';
import { NameViewServiceMock } from '../name-view.service.mock';
import { TrustAccountingDetailsComponent } from './trust-accounting-details.component';
import { TrustAccountingComponent, TrustAccountingTopic } from './trust-accounting.component';

describe('TrustAccountingComponent', () => {
  let component: TrustAccountingComponent;
  let modalService: ModalServiceMock;
  let localSettings: LocalSettingsMock;
  const serviceMock = new NameViewServiceMock();
  const changeDetectorRefMock = new ChangeDetectorRefMock();

  beforeEach(() => {
    modalService = new ModalServiceMock();
    localSettings = new LocalSettingsMock();
    component = new TrustAccountingComponent(serviceMock as any, changeDetectorRefMock as any, modalService as any, localSettings as any);
  });

  it('should create', () => {
    expect(component).toBeDefined();
  });

  it('should build grid options and set showWebLink value', () => {
    component.topic = new TrustAccountingTopic({ showWebLink: false, viewData: null });
    component.topic.params.viewData = {
        hostId: null
    };
    component.ngOnInit();

        expect(component.gridOptions).not.toBe(null);
        expect(component.showWebLink).toBe(false);
        expect(component.localBalanceTotal).not.toBe(null);
        expect(component.gridOptions.columns.length).toEqual(4);
        expect(component.gridOptions.columns[2].field === 'localBalance');
        expect(component.gridOptions.columns[3].field === 'foreignBalance');
    });
    it('encodes the name url correctly', () => {
        const link = component.encodeLinkData('1234 5');
        expect(link).toBe('api/search/redirect?linkData=%7B%22nameKey%22%3A%221234%205%22%7D');
    });
    it('correctly opens modal when values is clicked', () => {
        const data = {
            bankAccountNameKey: 2,
            bankAccountSeqKey: 3278,
            entityKey: 555,
            entity: 'big entity',
            bankAccount: 'big bank account'
        };
        component.viewData = {
            viewData: {
                nameId: 3
            }
        };

        component.openTrustDetails(data);
        expect(modalService.openModal).toHaveBeenCalledWith(TrustAccountingDetailsComponent, {
            animated: false,
            backdrop: 'static',
            class: 'modal-xl',
            initialState: {
                nameId: component.viewData.nameId,
                bankId: data.bankAccountNameKey,
                bankSeqId: data.bankAccountSeqKey,
                entityId: data.entityKey,
                entityName: data.entity,
                bankAccount: data.bankAccount
            }
        });
    });
});