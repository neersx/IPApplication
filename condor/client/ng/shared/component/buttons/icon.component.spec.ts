import { async } from '@angular/core/testing';
import { IconComponent } from './icon.component';

describe('IconComponent', () => {
  let component: IconComponent;

  beforeEach(() => {
    component = new IconComponent();
  });

  it('should create the icon', async(() => {
    expect(component).toBeTruthy();
  }));

  it('should set classes', () => {
    component.name = 'floppy';
    component.large = true;
    component.class = 'test';
    component.ngOnInit();
    expect(component.mainClass$.getValue()).toEqual('cpa-icon cpa-icon-floppy test cpa-icon-lg');
    expect(component.iconClass).toEqual('cpa-icon cpa-icon-floppy');
    expect(component.ilarge).toEqual(' cpa-icon-lg');
  });
  it('should set additional classes', () => {
    component.class = 'test';
    component.circle = true;
    component.ngOnInit();
    expect(component.mainClass$.getValue()).toContain('cpa-icon-stack');
    expect(component.additionalClass$.getValue()).toContain('fa cpa-icon-circle cpa-icon-stack-2x test');
    expect(component.subClass$.getValue()).toContain('cpa-icon cpa-icon-question-circle cpa-icon-stack-1x cpa-icon-inverse');
  });
});
