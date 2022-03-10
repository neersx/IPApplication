import { HttpClientModule } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, forwardRef, LOCALE_ID, NO_ERRORS_SCHEMA, ViewChild } from '@angular/core';
import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { NG_VALUE_ACCESSOR } from '@angular/forms';
import { TimePickerModule } from '@progress/kendo-angular-dateinputs';
import { ColumnListComponent } from '@progress/kendo-angular-grid';
import { IntlModule } from '@progress/kendo-angular-intl';
import { TranslationServiceMock } from 'ajs-upgraded-providers/mocks/translation-service.mock';
import { Translate } from 'ajs-upgraded-providers/translate.mock';
import { TranslationService } from 'ajs-upgraded-providers/translation.service.provider';
import { LocaleServiceMock } from 'core/locale-service.mock';
import { LocaleService } from 'core/locale.service';
import { TooltipModule } from 'ngx-bootstrap/tooltip';
import { BaseCommonModule } from 'shared/base.common.module';
import { IpxTimePickerComponent } from './ipx-time-picker.component';

@Component({
    selector: 'test-host',
    template: '<ipx-time-picker [(ngModel)]="testData"></ipx-time-picker>',
    changeDetection: ChangeDetectionStrategy.OnPush
})
class TestHostComponent {
    @ViewChild(IpxTimePickerComponent, { static: true }) ipxTimePickerComponent: IpxTimePickerComponent;
    testData = new Date();
}

describe('IpxTimePickerComponent', () => {
    let fixture: ComponentFixture<IpxTimePickerComponent>;
    let hostFixture: ComponentFixture<TestHostComponent>;
    let hostComponent: TestHostComponent;
    let localeService: LocaleService;
    let translationService: TranslationService;

    beforeEach(async(() => {
        TestBed.configureTestingModule({
            declarations: [IpxTimePickerComponent, TestHostComponent, Translate],
            imports: [TooltipModule.forRoot(), TimePickerModule, IntlModule, BaseCommonModule, HttpClientModule],
            providers: [
                { provide: LOCALE_ID, useValue: 'en' },
                { provide: LocaleService, useClass: LocaleServiceMock },
                { provide: TranslationService, useClass: TranslationServiceMock },
                {
                    provide: NG_VALUE_ACCESSOR,
                    useExisting: forwardRef(() => IpxTimePickerComponent),
                    multi: true
                }
            ],
            schemas: [NO_ERRORS_SCHEMA]

        }).compileComponents();
    }));

    beforeEach(() => {
        fixture = TestBed.createComponent(IpxTimePickerComponent);
        localeService = fixture.debugElement.injector.get(LocaleService);
        translationService = fixture.debugElement.injector.get(TranslationService);
        hostFixture = TestBed.createComponent(TestHostComponent);
        hostComponent = hostFixture.componentInstance;
    });

    it('should create', () => {
        hostFixture.detectChanges();
        expect(hostComponent.ipxTimePickerComponent).toBeTruthy();
    });

    // test to check if the host component has received the changed time
    it('should set the host ngModel bound date to date based on the value', () => {
        const a = hostComponent.testData;
        hostFixture.detectChanges();
        const changedTime = new Date(a.setHours(a.getHours() - 2));
        hostComponent.ipxTimePickerComponent.timeChanged(changedTime);
        expect(hostComponent.testData.toString()).toMatch(changedTime.toString());
    });
    it('should reset seconds component if showSeconds is false', () => {
        const a = hostComponent.testData;
        hostComponent.ipxTimePickerComponent.showSeconds = false;
        hostFixture.detectChanges();
        const changedTime = new Date(a.setSeconds(30));
        hostComponent.ipxTimePickerComponent.timeChanged(changedTime);
        expect(hostComponent.ipxTimePickerComponent.value.getSeconds()).toBe(0);
    });
    it('for elapsedTime, should set the date to default date with time based on the value', () => {
        const a = new Date(1899, 0, 1);
        const hours = a.getHours() + 1;
        hostComponent.ipxTimePickerComponent.isElapsedTime = true;
        hostFixture.detectChanges();
        const changedTime = new Date(a.setHours(hours));
        hostComponent.ipxTimePickerComponent.timeChanged(changedTime);
        expect(hostComponent.ipxTimePickerComponent.value.toString()).toMatch(changedTime.toString());
    });
    it('should initialise steps where specified', () => {
        hostComponent.ipxTimePickerComponent.timeInterval = 15;
        hostFixture.detectChanges();
        expect(hostComponent.ipxTimePickerComponent.wrapper.steps.minute).toBe(15);
    });
    it('should initialise steps where zero or not specified', () => {
        hostComponent.ipxTimePickerComponent.timeInterval = 0;
        hostFixture.detectChanges();
        expect(hostComponent.ipxTimePickerComponent.wrapper.steps).toEqual(expect.objectContaining({}));
        hostComponent.ipxTimePickerComponent.timeInterval = null;
        hostFixture.detectChanges();
        expect(hostComponent.ipxTimePickerComponent.wrapper.steps).toEqual(expect.objectContaining({}));
    });
});
