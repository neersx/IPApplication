import { AppContextServiceMock } from 'core/app-context.service.mock';
import { ChangeDetectorRefMock, ElementRefTypeahedMock } from 'mocks';
import { TopHeaderComponent } from './ipx-top-header.component';

describe('topheader', () => {
  let component: TopHeaderComponent;
  let appContext: AppContextServiceMock;
  let cdr: ChangeDetectorRefMock;

  beforeEach(() => {
    appContext = new AppContextServiceMock();
    cdr = new ChangeDetectorRefMock();
    const elementRef = new ElementRefTypeahedMock();
    component = new TopHeaderComponent(appContext as any, elementRef as any, cdr as any);
  });

  it('should returns show link flag and showTimer flag as false', () => {
    expect(component.showLink).toEqual(false);
    expect(component.showTimerInfo).toEqual(false);
  });

  it('should returns show link flag as true when appContext is set', () => {
    appContext.appContext = {
      user: {
        permissions: {
          canShowLinkforInprotechWeb: true
        }
      }
    };
    component.ngOnInit();
    expect(component.showLink).toEqual(true);
  });

  it('should returns showTimerInfo flag as true when appContext is set', () => {
    appContext.appContext = {
      user: {
        permissions: {
          canAccessTimeRecording: true
        }
      }
    };
    component.ngOnInit();
    expect(component.showTimerInfo).toEqual(true);
  });

  it('should contains correct link', () => {
    expect(component.baseUrl).toEqual('../');
  });
});
