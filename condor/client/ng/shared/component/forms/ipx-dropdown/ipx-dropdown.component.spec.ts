import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { TranslateFakeLoader, TranslateLoader, TranslateModule, TranslateService } from '@ngx-translate/core';
import { TooltipModule } from 'ngx-bootstrap/tooltip';
import { IpxDropdownComponent } from './ipx-dropdown.component';

describe('IpxDropdownComponent', () => {
    let component: IpxDropdownComponent;
    let fixture: ComponentFixture<IpxDropdownComponent>;

    beforeEach(() => {
        TestBed.configureTestingModule({
            imports: [FormsModule,
                TooltipModule.forRoot(),
                TranslateModule.forRoot({
                    loader: {
                        provide: TranslateLoader,
                        useClass: TranslateFakeLoader
                    }
                })],
            declarations: [IpxDropdownComponent],
            providers: [
                TranslateService
            ]
        });
        fixture = TestBed.createComponent(IpxDropdownComponent);
        component = fixture.componentInstance;
        fixture.detectChanges();
        component.value = { name: 4, value: 'not exist value' };
        component.displayField = 'value';
        component.options = [
            {
                name: 3,
                value: 'Attorney Case'
            },
            {
                name: 1035,
                value: 'bikesh appeal'
            },
            {
                name: 22,
                value: 'BikeshAppeal'
            }];
    });

    it('should create dropdown component', () => {
        expect(component).toBeTruthy();
    });

    it('should set applyTranslate value', async(() => {
        const applyTranslate = component.shouldTranslate();
        expect(applyTranslate).toBe(true);

    }));

    it('should verify 1st option in dropdown list', async(() => {
        expect(component.value).not.toBeNull();
    }));

    describe('ngOnInit', () => {
        it('should set identifier to id', () => {
            component.getId = (id) => 'retrievedIdentifier';

            component.ngOnInit();

            expect(component.identifier).toEqual('retrievedIdentifier');
        });
    });
});
