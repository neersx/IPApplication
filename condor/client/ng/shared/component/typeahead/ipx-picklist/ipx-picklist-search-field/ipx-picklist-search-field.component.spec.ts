import { IpxPicklistSearchFieldComponent, NavigationEnum } from './ipx-picklist-search-field.component';

describe('IpxPicklistSearchFieldComponent', () => {
  let component: IpxPicklistSearchFieldComponent;

  beforeEach(() => {
    component = new IpxPicklistSearchFieldComponent();
    component.model = 'initial';
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should search correctly', () => {
    spyOn(component.onSearch, 'emit');
    component.search();
    // tslint:disable-next-line: no-unbound-method
    expect(component.onSearch.emit).toHaveBeenCalledWith({ action: '', value: 'initial' });
  });

  it('should emit correct value on keyUp', () => {
    spyOn(component.onKeyUp, 'emit');
    component.keyUp();
    expect(component.onKeyUp.emit).toHaveBeenCalledWith({ action: '', value: 'initial' });
  });
  it('should clear correctly', () => {
    spyOn(component.onClear, 'emit');
    component.navigation = NavigationEnum.current;
    component.clear();
    // tslint:disable-next-line: no-unbound-method
    expect(component.onClear.emit).toHaveBeenCalled();
  });
});
