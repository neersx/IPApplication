import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { SharedModule } from 'shared/shared.module';
import { PostSelectedModule } from './post-selected/post-selected.module';
import { PostTimeDialogService } from './post-time-dialog.service';
import { PostTimeComponent } from './post-time.component';
import { PostTimeService } from './post-time.service';

@NgModule({
    imports: [
        SharedModule,
        PostSelectedModule,
        FormsModule
    ],
    declarations: [
        PostTimeComponent
    ],
    exports: [
        PostTimeComponent
    ],
    providers: [PostTimeService]
})
export class PostTimeModule {

}
