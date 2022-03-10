import { AppContextServiceMock } from 'core/app-context.service.mock';
import { ChangeDetectorRefMock } from 'mocks';
import { Observable } from 'rxjs';
import { LinksComponent } from './links.component';

describe('LinksComponent', () => {
  let component: LinksComponent;
  let linkService: any;

  beforeEach(() => {
    linkService = { get: jest.fn().mockReturnValue(new Observable()) };
    component = new LinksComponent(new AppContextServiceMock() as any, linkService, new ChangeDetectorRefMock() as any);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should get called', () => {
    component.ngOnInit();
    expect(linkService.get).toHaveBeenCalled();
  });

});
