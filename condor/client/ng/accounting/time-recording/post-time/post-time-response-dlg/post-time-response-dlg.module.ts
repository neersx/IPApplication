import { NgModule } from '@angular/core';
import { SharedModule } from 'shared/shared.module';
import { PostTimeResponseDlgComponent } from './post-time-response-dlg.component';

@NgModule({
    imports: [
        SharedModule
    ],
    declarations: [
        PostTimeResponseDlgComponent
    ],
    exports: [
        PostTimeResponseDlgComponent
    ]
})
export class PostTimeResponseDlgModule {

}
