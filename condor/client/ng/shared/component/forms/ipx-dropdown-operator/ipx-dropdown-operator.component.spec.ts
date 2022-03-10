import { ChangeDetectorRefMock, ElementRefTypeahedMock, NgControl, Renderer2Mock } from 'mocks';
import { IpxDropdownOperatorComponent } from './ipx-dropdown-operator.component';

describe('IpxDropdownOperatorComponent', () => {
  let component: IpxDropdownOperatorComponent;
  const element = new ElementRefTypeahedMock();
  beforeEach(() => {

    component = new IpxDropdownOperatorComponent(Renderer2Mock as any, NgControl as any, element as any,
      ChangeDetectorRefMock as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
    component.initializeField();
  });

  it('should initialize Field correctly', () => {
    const dateOptions = {
      withinLast: { key: 'L', value: 'operators.withinLast' },
      withinNext: { key: 'N', value: 'operators.withinNext' },
      specificDate: { key: 'sd', value: 'operators.SpecificDates' }
    };
    component.initializeField();
    expect(component.dateOptions).toEqual(dateOptions);
  });

});
