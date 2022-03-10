import { async, TestBed } from '@angular/core/testing';
import { TranslateFakeLoader, TranslateLoader, TranslateModule, TranslateService } from '@ngx-translate/core';
import { TooltipModule } from 'ngx-bootstrap/tooltip';
import { AddButtonComponent, ApplyButtonComponent, ClearButtonComponent, CloseButtonComponent, DeleteButtonComponent, IconButtonComponent, RevertButtonComponent, SaveButtonComponent, StepButtonComponent } from './buttons.component';
import { IconComponent } from './icon.component';

describe('ButtonsComponent', () => {
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
                TranslateService
            ],
            declarations: [
                AddButtonComponent,
                ApplyButtonComponent,
                ClearButtonComponent,
                CloseButtonComponent,
                IconButtonComponent,
                RevertButtonComponent,
                SaveButtonComponent,
                StepButtonComponent,
                IconComponent,
                DeleteButtonComponent
            ]
        }).compileComponents().catch();
    }));

    it('should create the add button', async(() => {
        const fixture = TestBed.createComponent(AddButtonComponent);
        const component = fixture.componentInstance;
        expect(component).toBeTruthy();
    }));
    it('add button click should emit onClick event', (done) => {
        const fixture = TestBed.createComponent(AddButtonComponent);
        const component = fixture.componentInstance;
        const event = new Event('onClick');
        component.onclick.subscribe(g => {
            expect(g).toEqual(event);
            done();
        });
        component.onClickButton(event);
    });
    it('should create the save button', async(() => {
        const fixture = TestBed.createComponent(SaveButtonComponent);
        const component = fixture.componentInstance;
        expect(component).toBeTruthy();
    }));
    it('should create the apply button', async(() => {
        const fixture = TestBed.createComponent(ApplyButtonComponent);
        const component = fixture.componentInstance;
        expect(component).toBeTruthy();
    }));
    it('should create the clear button', async(() => {
        const fixture = TestBed.createComponent(ClearButtonComponent);
        const component = fixture.componentInstance;
        expect(component).toBeTruthy();
    }));
    it('should create the close button', async(() => {
        const fixture = TestBed.createComponent(CloseButtonComponent);
        const component = fixture.componentInstance;
        expect(component).toBeTruthy();
    }));
    it('should create the icon button', async(() => {
        const fixture = TestBed.createComponent(IconButtonComponent);
        const component = fixture.componentInstance;
        expect(component).toBeTruthy();
    }));
    it('should create the step button', async(() => {
        const fixture = TestBed.createComponent(StepButtonComponent);
        const component = fixture.componentInstance;
        expect(component).toBeTruthy();
    }));
    it('should create the revert button', async(() => {
        const fixture = TestBed.createComponent(RevertButtonComponent);
        const component = fixture.componentInstance;
        expect(component).toBeTruthy();
    }));
    it('should create the delete button', async(() => {
        const fixture = TestBed.createComponent(DeleteButtonComponent);
        const component = fixture.componentInstance;
        expect(component).toBeTruthy();
    }));
});
