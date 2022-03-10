import { ChangeDetectionStrategy, Component } from '@angular/core';
import { AppContextService } from 'core/app-context.service';
import { LocaleService } from 'core/locale.service';
import { take } from 'rxjs/operators';

@Component({
  selector: 'time-picker-dev',
  templateUrl: 'time-picker.component.dev.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class TimePickerDevComponent {
  showSeconds = false;
  disabled = false;
  value = new Date();

  constructor(private readonly appContextService: AppContextService, private readonly localeService: LocaleService) {
    this.appContextService.appContext$
      .pipe(take(1))
      .subscribe((value: any) => {
        this.localeService.set(value.user.preferences.kendoLocale);
      });
  }

  onBlur(): void {
    console.log('on blur fired');
  }

  timeChanged(event: any): void {
    console.log(event);
  }
}
