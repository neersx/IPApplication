import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { PopoverModule } from 'ngx-bootstrap/popover';
import { IpxInlineDialogComponent } from './ipx-inline-dialog.component';

describe('IpxInlineDialogComponent', () => {
  let component: IpxInlineDialogComponent;
  let fixture: ComponentFixture<IpxInlineDialogComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [PopoverModule.forRoot()],
      declarations: [IpxInlineDialogComponent]
    })
      .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(IpxInlineDialogComponent);
    component = fixture.componentInstance;
    component.templateRef = null;
    fixture.detectChanges();
  });
  it('should create', () => {
    expect(component).toBeTruthy();
  });
  it('should use template if content not provided', () => {
    fixture.detectChanges();
    expect(component.tooltipContent).toBe(component.templateRef);
  });
});