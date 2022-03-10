import { ChangeDetectorRefMock, ElementRefTypeahedMock, NgControl } from 'mocks';
import { IpxTextDropdownGroupComponent } from './ipx-text-dropdown-group.component';

describe('IpxTextDropdownGroupComponent', () => {
  let component: IpxTextDropdownGroupComponent;
  const element = new ElementRefTypeahedMock();
  const changedetect = new ChangeDetectorRefMock();
  beforeEach(() => {
    component = new IpxTextDropdownGroupComponent(NgControl as any, element as any,
      changedetect as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should set the modal correct with writevalue method', () => {
    const controlValue = { type: 'D', value: 0 };
    component.textField = 'type';
    component.optionField = 'value';
    component.model = {};
    component.writeValue(controlValue);
    expect(component.model).toEqual(controlValue);
  });

  it('should set the default value with writevalue method', () => {
    const controlValue = null;
    component.writeValue(controlValue);
    expect(component.textValue).toEqual('');
    expect(component.option).toEqual(null);
  });

  it('should set testfield', () => {
    component.setTextField(true);
    expect(component.textValue).toEqual('');
  });
});
