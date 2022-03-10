import { CommonModule } from '@angular/common';
import { LOCALE_ID, NgModule } from '@angular/core';
import { IntlModule } from '@progress/kendo-angular-intl';
import { ByteSizeFormatPipe } from './byte-size-format.pipe';
import { DurationFormatPipe } from './duration-format.pipe';
import { HtmlPipe } from './html.pipe';
import { LocalCurrencyFormatPipe } from './local-currency-format.pipe';
import { LocaleDatePipe } from './locale-date.pipe';
import { RemoveTimezonePipe } from './remove-timezone.pipe';
import { SanitizeHtmlPipe } from './sanitize-html.pipe';

@NgModule({
    declarations: [
        HtmlPipe,
        DurationFormatPipe,
        LocalCurrencyFormatPipe,
        LocaleDatePipe,
        SanitizeHtmlPipe,
        RemoveTimezonePipe,
        ByteSizeFormatPipe
    ],
    imports: [
        CommonModule, IntlModule
    ],
    exports: [
        HtmlPipe,
        DurationFormatPipe,
        LocalCurrencyFormatPipe,
        LocaleDatePipe,
        SanitizeHtmlPipe,
        RemoveTimezonePipe,
        ByteSizeFormatPipe
    ],
    providers: [{
        provide: LOCALE_ID, useValue: 'en'
    }, DurationFormatPipe,
        LocaleDatePipe]
})
export class PipesModule { }
