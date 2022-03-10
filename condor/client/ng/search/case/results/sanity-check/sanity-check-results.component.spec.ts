import { CaseDetailServiceMock } from 'cases/case-view/case-detail.service.mock';
import { CommonUtilityServiceMock } from 'core/common.utility.service.mock';
import { ChangeDetectorRefMock, StateServiceMock, TranslateServiceMock } from 'mocks';
import { RightBarNavServiceMock } from 'rightbarnav/rightbarnavservice.mock';
import { SanityCheckResultsComponent } from './sanity-check-results.component';
import { SanityCheckResultServiceMock } from './sanity-check-results.service.mock';

describe('SanityCheckResultsComponent', () => {
  let component: SanityCheckResultsComponent;
  const stateServiceMock = new StateServiceMock();
  const caseViewServiceMock = new CaseDetailServiceMock();
  const changeDetectorRefMock = new ChangeDetectorRefMock();
  const translateMock = new TranslateServiceMock();
  const commonServiceMock = new CommonUtilityServiceMock();
  const rightBarNavMock = new RightBarNavServiceMock();

  beforeEach(() => {
    component = new SanityCheckResultsComponent(commonServiceMock as any, changeDetectorRefMock as any, SanityCheckResultServiceMock as any,
      caseViewServiceMock as any, stateServiceMock as any, translateMock as any, rightBarNavMock as any);
  });

  it('should create', () => {
    expect(component).toBeDefined();
  });

  it('validate ngOnInit', () => {
    component.ngOnInit();
    expect(component.gridOptions).toBeDefined();
    expect(component.gridOptions).not.toBe(null);
    expect(component.gridOptions.columns.length).toEqual(6);
    expect(component.gridOptions.columns[2].field === 'caseOffice');
    expect(component.gridOptions.columns[3].field === 'staffName');
    expect(component.gridOptions.columns[4].field === 'signatoryName');
  });

  it('validate getFlagStyle with Error', () => {
    const style = component.getFlagStyle('Error');
    expect(style).toMatchObject({ color: '#ff0000' });
  });
  it('validate getFlagStyle with ByPassError', () => {
    const style = component.getFlagStyle('ByPassError');
    expect(style).toMatchObject({ color: '#ffa500' });
  });
  it('validate getFlagStyle with Information', () => {
    const style = component.getFlagStyle('Information');
    expect(style).toMatchObject({ color: '#ffff00' });
  });
});