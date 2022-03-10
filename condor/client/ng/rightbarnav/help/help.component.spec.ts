import { AppContextServiceMock } from 'core/app-context.service.mock';
import { BsModalRefMock, ChangeDetectorRefMock } from 'mocks';
import { Observable } from 'rxjs';
import { HelpComponent } from './help.component';

describe('HelpComponent', () => {
  let component: HelpComponent;
  let helpService: any;

  beforeEach((() => {
    helpService = { get: jest.fn().mockReturnValue(new Observable()) };

    component = new HelpComponent(helpService, new AppContextServiceMock() as any, new BsModalRefMock() as any, new ChangeDetectorRefMock() as any);
  }));

  it('should component initialize', () => {
    expect(component).toBeTruthy();
  });

  it('should create', () => {
    component.ngOnInit();
    expect(helpService.get).toHaveBeenCalled();
  });

});