import { async } from '@angular/core/testing';
import { CaseSearchHelperServiceMock, ChangeDetectorRefMock } from 'mocks';
import { StepsPersistanceSeviceMock } from 'search/multistepsearch/steps.persistence.service.mock';
import { AttributesComponent } from '.';
describe('AttributesComponent', () => {
  let c: AttributesComponent;
  let viewData: any;
  let cdr: ChangeDetectorRefMock;
  beforeEach(() => {
    cdr = new ChangeDetectorRefMock();
    c = new AttributesComponent(StepsPersistanceSeviceMock as any, CaseSearchHelperServiceMock as any, cdr as any);
    c.attributes = [{ key: 'a' }];
    viewData = {
      isExternal: false,
      attributes: [{ key: 'a' }]
    };
    c.topic = {
      params: {
        viewData
      },
      key: 'attributes',
      title: 'attributes'
    };
  });

  it('should create the component', async(() => {
    expect(c).toBeTruthy();
  }));
  it('initialises defaults', () => {
    expect(c.attributes).toEqual(viewData.attributes);
  });
  it('should return case attributes filters', () => {
    const attribute1 = {
      attributeOperator: '1',
      attributeType: { key: '1' },
      attributeValue: { key: '2' }
    };
    const attribute2 = {
      attributeOperator: '5',
      attributeType: { key: '1' },
      attributeValue: { key: '2' }
    };
    const attribute3 = {
      attributeOperator: '0',
      attributeType: null,
      attributeValue: null
    };
    c.formData = {
      booleanAndOr: 1,
      attribute1,
      attribute2,
      attribute3
    };

    const r = c.getFilterCriteria();
    expect(r.attributeGroup.booleanOr).toEqual(1);
    expect(r.attributeGroup).toEqual(
      jasmine.objectContaining({
        booleanOr: 1,
        attribute: [
          { operator: '1', typeKey: '1', attributeKey: '2' },
          { operator: '5', typeKey: '1', attributeKey: null }
        ]
      })
    );
  });
});
