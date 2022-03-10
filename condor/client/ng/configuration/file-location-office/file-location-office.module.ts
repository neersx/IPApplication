import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { SharedModule } from 'shared/shared.module';
import { fileLocationOffice } from './file-location-office-states';
import { FileLocationOfficeComponent } from './file-location-office.component';
import { FileLocationOfficeService } from './file-location-office.service';

@NgModule({
    declarations: [
        FileLocationOfficeComponent
    ],
    imports: [
        SharedModule,
        ButtonsModule,
        UIRouterModule.forChild({ states: [fileLocationOffice] })
    ],
    providers: [
        FileLocationOfficeService
    ],
    exports: [
    ]
})
export class FileLocationOfficeModule { }