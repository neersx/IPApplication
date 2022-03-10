import { async } from '@angular/core/testing';
import { ChangeDetectorRefMock, IpxGridOptionsMock } from 'mocks';
import { of } from 'rxjs';
import * as _ from 'underscore';
import { RenewalsComponent, RenewalsTopic } from './renewals.component';

describe('RenewalsComponent', () => {
  let c: RenewalsComponent;
  let service: any;
  let cdr: ChangeDetectorRefMock;
  let searchFnSpy: any;

  const data: any = {
    caseStatus: 'renew pending',
    renewalStatus: 'Pending',
    caseId: 12345,
    screenControl: 111
  };
  const renewalsData: any = {
    abcd: 'efjh',
    renewalNotes: 'notes',
    standingInstruction: {
      instruction: 'stadinst',
      instructionTypeDescription: 'SIT'
    },
    renewalNames: {
      type: 'Renewals Debtor',
      typeId: 'Z',
      attention: 'Mrs Aileen Cornish',
      address: 'Abc Street↵CDy Lane↵Australia',
      phone: '1234 5678',
      displayFlags: 4103
    }
  };

  beforeEach(async(() => {
    cdr = new ChangeDetectorRefMock();
    service = {
      getCaseRenewalsData$: jest.fn(() => {
        searchFnSpy = c.gridOptions._search = jest.fn();

        return of(renewalsData);
      })
    };
    c = new RenewalsComponent(service, cdr as any);
    c.isLoaded = false;
    c.renewalDetailTemplate = null;
    c.topic = new RenewalsTopic({ viewData: data, showWebLink: true });
  }));

  it('should set the grid, detail template and rebuild it', () => {
    expect(c.isLoaded).toBe(false);
    c.ngOnInit();
    const grid = c.gridOptions;
    expect(grid).toBeDefined();
    expect(c.renewalDetailTemplate).toBeDefined();
    expect(grid.detailTemplate).toBe(c.renewalDetailTemplate);
    expect(c.isLoaded).toBe(true);
  });

  it('should create the component and initialise values', async(() => {
    expect(c).toBeTruthy();
    c.ngOnInit();

    expect(service.getCaseRenewalsData$).toHaveBeenCalledWith(12345, 111);
    expect(cdr.detectChanges).toHaveBeenCalled();
    expect(c.data.caseStatus).toBe(data.caseStatus);
    expect(c.data.renewalStatus).toBe(data.renewalStatus);
    expect(c.data.abcd).toBe(renewalsData.abcd);
    expect(c.data.renewalNotes).toBe(renewalsData.renewalNotes);
    expect(c.data.standingInstruction.instruction).toBe(renewalsData.standingInstruction.instruction);
    expect(c.data.renewalNames.type).toBe(renewalsData.renewalNames.type);
    expect(searchFnSpy).toHaveBeenCalled();
    expect(c.showWebLink).toBe(true);
  }));
});
