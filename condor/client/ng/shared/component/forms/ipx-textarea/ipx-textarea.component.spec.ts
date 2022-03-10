import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { IpxTextareaComponent } from './ipx-textarea.component';

describe('IpxTextareaComponent', () => {
  let component: IpxTextareaComponent;
  let fixture: ComponentFixture<IpxTextareaComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ IpxTextareaComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(IpxTextareaComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
