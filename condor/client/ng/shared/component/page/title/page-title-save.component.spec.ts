import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { TranslateFakeLoader, TranslateLoader, TranslateModule, TranslateService } from '@ngx-translate/core';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { TooltipModule } from 'ngx-bootstrap/tooltip';
import { IconButtonComponent, RevertButtonComponent, SaveButtonComponent } from '../../buttons/buttons.component';
import { IconComponent } from '../../buttons/icon.component';
import { ConfirmBeforePageChangeDirective } from '../confirm-before-page-change.directive';
import { PageTitleSaveComponent } from './page-title-save.component';

describe('PageTitleSaveComponent', () => {
  let component: PageTitleSaveComponent;
  let fixture: ComponentFixture<PageTitleSaveComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
        TooltipModule.forRoot(),
        TranslateModule.forRoot({
          loader: {
            provide: TranslateLoader,
            useClass: TranslateFakeLoader
          }
        })
      ],
      providers: [
        TranslateService,
        NotificationService
      ],
      declarations: [
        PageTitleSaveComponent,
        SaveButtonComponent,
        RevertButtonComponent,
        IconButtonComponent,
        ConfirmBeforePageChangeDirective,
        IconComponent
      ]
    }).compileComponents().catch();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(PageTitleSaveComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create the component', async(() => {
    expect(component).toBeTruthy();
    expect(component.isDeleteAvailable).toBe(false);
    expect(component.isDiscardAvailableInternal).toBeFalsy();
    expect(component.isSaveAvailableInternal).toBeFalsy();
    expect(component.isDiscardEnabled).toBeFalsy();
    expect(component.isSaveEnabled).toBeFalsy();
    expect(component.isDeleteEnabled).toBeFalsy();
  }));

  it('save button click should emit onSave event', (done) => {
    component.onSave.subscribe(g => {
      expect(g).toEqual(undefined);
      done();
    });
    component.doSave();
  });
  it('delete button click should emit onDelete event', (done) => {
    component.onDelete.subscribe(g => {
      expect(g).toEqual(undefined);
      done();
    });
    component.doDelete();
  });
});
