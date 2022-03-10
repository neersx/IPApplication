import { EventEmitterMock } from 'mocks';
import { of } from 'rxjs';
import { CaseDetailServiceMock } from '../case-detail.service.mock';
import { StandingInstructionsComponent, StandingInstructionsTopic } from './standing-instructions.component';

describe('StandingInstructionsComponent', () => {
  let component: StandingInstructionsComponent;
  let service: CaseDetailServiceMock;

  beforeEach(() => {
    service = new CaseDetailServiceMock();
    component = new StandingInstructionsComponent(service as any);
  });

  it('should create the component', () => {
    expect(component).toBeTruthy();
  });

  it('should build grid options and set showWebLink value', () => {
    component.topic = new StandingInstructionsTopic({ showWebLink: false, viewData: null });
    component.ngOnInit();

    expect(component.gridOptions).not.toBe(null);
    expect(component.showWebLink).toBe(false);
  });

  it('encodes the name url correctly', () => {
    const link = component.encodeLinkData('1234 5');
    expect(link).toBe('api/search/redirect?linkData=%7B%22nameKey%22%3A%221234%205%22%7D');
  });

  it('should raise count emit for topic, after data received', () => {
    const setCountMock = new EventEmitterMock<number>();
    component.topic = new StandingInstructionsTopic({ showWebLink: false, viewData: null});
    component.topic.setCount = setCountMock as any;

    const data = [1, 2, 3];
    service.getStandingInstructions$.mockReturnValue(of(data));
    component.ngOnInit();

    component.gridOptions.onDataBound(data);

    expect(component.topic.setCount.emit).toHaveBeenCalledWith(3);
  });
});
