import { NgModule } from '@angular/core';
import { SharedModule } from 'shared/shared.module';
import { CasenamesWarningsComponent } from './case-names-warning/casenames-warnings.component';
import { NameOnlyWarningsComponent } from './name-only-warnings/name-only-warnings.component';
import { WarningCheckerService } from './warning-checker.service';
import { WarningService } from './warning-service';
export { CasenamesWarningsComponent } from './case-names-warning/casenames-warnings.component';
export { NameOnlyWarningsComponent } from './name-only-warnings/name-only-warnings.component';

@NgModule({
    imports: [
        SharedModule
    ],
    declarations: [
        CasenamesWarningsComponent,
        NameOnlyWarningsComponent
    ],
    providers: [
        WarningService,
        WarningCheckerService
    ],
    exports: [
        CasenamesWarningsComponent,
        NameOnlyWarningsComponent
    ]
})
export class WarningsModule {

}
