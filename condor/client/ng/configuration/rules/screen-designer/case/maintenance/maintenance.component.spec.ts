import { MaintenanceComponent } from './maintenance.component';

describe('MaintenanceComponent', () => {
  let component: MaintenanceComponent;

  beforeEach(() => {
    component = new MaintenanceComponent({ getNavData: jest.fn() } as any, { current: { name: 'stateName' } } as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
