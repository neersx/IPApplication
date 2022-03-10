import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { PopoverModule } from 'ngx-bootstrap/popover';
import { IpxHoverHelpComponent } from './ipx-hover-help.component';

describe('IpxHoverHelpComponent', () => {
  let component: IpxHoverHelpComponent;
  let fixture: ComponentFixture<IpxHoverHelpComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [ PopoverModule.forRoot() ],
      declarations: [ IpxHoverHelpComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(IpxHoverHelpComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
  it('should exist', () => {
    expect(component).toBeDefined();
  });
  it('should not display hover if content not provided', () => {
    fixture.detectChanges();
    expect(component.hasData).toBe(false);
  });
it('should display hover if content provided', () => {
    component.content = 'test hover content';
    fixture.detectChanges();
    expect(component.hasData).toBe(true);
  });
});