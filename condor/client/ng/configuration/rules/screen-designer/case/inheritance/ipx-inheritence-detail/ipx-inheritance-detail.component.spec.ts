import { ScreenDesignerCriteriaDetails } from 'configuration/rules/screen-designer/screen-designer.service';
import { StateServiceMock } from 'mocks';
// tslint:disable:no-string-literal
import { of } from 'rxjs';
import { IpxInheritanceDetailComponent } from './ipx-inheritance-detail.component';

describe('IpxInheritenceDetailComponent', () => {
  let component: IpxInheritanceDetailComponent;
  let mockSearchService: any;
  let mockStateService: any;

  beforeEach(() => {
    mockSearchService = {
      getCriteriaDetails$: jest.fn(),
      pushState: jest.fn()
    };
    mockStateService = new StateServiceMock();
    component = new IpxInheritanceDetailComponent(mockStateService, mockSearchService);
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should retrieve details', () => {
    mockSearchService.getCriteriaDetails$.mockReturnValue(of(new ScreenDesignerCriteriaDetails()));
    component.criteriaNo = 2001;
    expect(mockSearchService.getCriteriaDetails$).toHaveBeenCalledWith(2001);
  });

  it('should navigate to criteria correctly', () => {
    const details = new ScreenDesignerCriteriaDetails();
    details.id = 2001;
    component.$criteriaDetails.next(details);
    component.rowKey = 2;

    component.navigateToCriteria();
    expect(mockStateService['go']).toHaveBeenCalledWith('screenDesignerCaseCriteria', { id: 2001, rowKey: 2 });
  });
});
