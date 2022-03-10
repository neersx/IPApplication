import { ChangeDetectorRefMock, ElementRefMock } from 'mocks';
import { ViewPortService } from './../../../shared/shared-services/view-port.service';
import { CustomContentComponent } from './custom-content.component';
describe('CustomContentComponent', () => {
  let component: CustomContentComponent;
  let changeRefMock: ChangeDetectorRefMock;
  let elementRef: ElementRefMock;
  let viewPortService: ViewPortService;
  beforeEach(() => {
    changeRefMock = new ChangeDetectorRefMock();
    elementRef = new ElementRefMock();
    viewPortService = new ViewPortService();
    component = new CustomContentComponent(elementRef as any, changeRefMock as any, viewPortService as any);
  });

  it('should create component', () => {
    expect(component).toBeTruthy();
  });

  it('should set the value of loadInView', () => {
    spyOn(viewPortService, 'isInView').and.returnValue(true);
    component.topic = {
      filters: { customContentUrl: '#' }, key: '',
      title: ''
    };
    component.ngAfterViewInit();
    expect(component.contentUrl).toEqual('#');
    expect(component.topic.loadedInView).toEqual(true);
  });

  it('should not set the value of loadInView', () => {
    spyOn(viewPortService, 'isInView').and.returnValue(false);
    component.ngAfterViewInit();
  });

  it('should  set the value of ngOnInit', () => {
    component.topic = {
      filters: { customContentUrl: '#', parentAccessAllowed: 'True' }, key: '',
      title: ''
    };
    component.ngOnInit();
    expect(component.parentAccessAllowed).toEqual(true);
  });
});