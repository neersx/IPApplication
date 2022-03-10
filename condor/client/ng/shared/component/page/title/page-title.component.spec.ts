import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { TranslateFakeLoader, TranslateLoader, TranslateModule, TranslateService } from '@ngx-translate/core';
import { PageTitleComponent } from './page-title.component';

describe('PageTitleComponent', () => {
  let component: PageTitleComponent;
  let fixture: ComponentFixture<PageTitleComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      imports: [
            TranslateModule.forRoot({
                        loader: {
                          provide: TranslateLoader,
                          useClass: TranslateFakeLoader
                        }
                      })
        ],
      providers: [
                    TranslateService
                  ],
      declarations: [
        PageTitleComponent
      ]
    }).compileComponents().catch();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(PageTitleComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create the icon', async(() => {
    expect(component).toBeTruthy();
  }));
});
