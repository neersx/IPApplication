import { FormGroup } from '@angular/forms';
import { BsModalRefMock, HttpClientMock } from 'mocks';
import { NotificationServiceMock } from 'mocks/notification-service.mock';
import { of } from 'rxjs';
import { KotFilterTypeEnum } from '../kot-text-types.model';
import { KotTextTypesService } from '../kot-text-types.service';
import { KotMaintainConfigComponent } from './kot-maintain-config.component';

describe('KotMaintainConfigComponent', () => {
  let component: KotMaintainConfigComponent;
  let notificationServiceMock: NotificationServiceMock;
  let httpMock: HttpClientMock;
  let service: KotTextTypesService;

  beforeEach(() => {
    httpMock = new HttpClientMock();
    httpMock.get.mockReturnValue(of({ id: 1, textType: 1 }));
    httpMock.post.mockReturnValue(of({}));

    service = new KotTextTypesService(httpMock as any);
    notificationServiceMock = new NotificationServiceMock();
    component = new KotMaintainConfigComponent(service as any, notificationServiceMock as any, new BsModalRefMock());
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialize on ngOnInit with appropriate state add', () => {
    spyOn(component, 'loadData');
    component.state = 'Add';
    component.ngOnInit();
    expect(component.loadData).toHaveBeenCalled();
    expect(component.entry).toBeDefined();
    expect(component.entry.id).toBeNull();
  });

  it('should initialize on ngOnInit with appropriate state edit', () => {
    spyOn(component, 'loadData');
    component.state = 'Edit';
    component.ngOnInit();
    service.getKotTextTypeDetails(1, KotFilterTypeEnum.byCase).subscribe(res => {
      expect(res).toBeDefined();
      expect(component.loadData).toHaveBeenCalled();
      expect(component.entry).toBeDefined();
      expect(component.entry.id).toBe(1);
    });
  });

  it('should initialize on ngOnInit with appropriate state', () => {
    spyOn(component, 'loadData');
    component.state = 'Duplicate';
    component.ngOnInit();
    service.getKotTextTypeDetails(1, KotFilterTypeEnum.byCase).subscribe(res => {
      expect(res).toBeDefined();
      expect(component.loadData).toHaveBeenCalled();
      expect(component.entry).toBeDefined();
      expect(component.entry.id).toBeNull();
      expect(component.entry.textType).toBeNull();
    });
  });

  it('should set formGroup appropriately with entry object', () => {

    component.ngOnInit();
    component.entry = {
      caseTypes: [],
      backgroundColor: '#ffff',
      hasBillingProgram: true,
      hasCaseProgram: true,
      hasNameProgram: true,
      hasTaskPlannerProgram: true,
      hasTimeProgram: true,
      id: 1,
      isDead: true,
      isRegistered: true,
      isPending: true,
      nameTypes: [],
      roles: [],
      textType: {
        key: 10,
        code: 'A',
        value: 'Abstract'
      }
    };
    component.loadData();
    expect(component.formGroup.value.caseTypes).toEqual(component.entry.caseTypes);
    expect(component.formGroup.value.color).toBeUndefined();
    expect(component.formGroup.value.textType).toEqual(component.entry.textType);
  });

  describe('Text type Save', () => {
    beforeEach(() => {
      component.onClose$.next = jest.fn() as any;
      (component as any).sbsModalRef = {
        hide: jest.fn()
      } as any;
      component.ngOnInit();
    });
    it('save form changes', () => {
      component.formGroup.controls.caseTypes.markAsDirty();
      component.save();
      service.saveKotTextType(null, KotFilterTypeEnum.byCase).subscribe(() => {
        expect(component.onClose$.next).toHaveBeenCalledWith(true);
        expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
      });
    });

    it('should handel error while saving form changes', () => {
      component.formGroup.controls.caseTypes.markAsDirty();
      component.save();
      service.saveKotTextType(null, KotFilterTypeEnum.byCase).subscribe((res) => {
        expect(res.error).toBeDefined();
      });
    });

    it('should reset form', () => {
      component.resetForm();
      expect(component.onClose$.next).toHaveBeenCalledWith(false);
      expect((component as any).sbsModalRef.hide).toHaveBeenCalled();
    });
    it('cancel form changes', () => {
      component.formGroup = new FormGroup({});
      (component as any).formGroup = {
        reset: jest.fn()
      } as any;
      component.cancel();
      expect(component.formGroup.reset).toHaveBeenCalled();
    });
  });
});