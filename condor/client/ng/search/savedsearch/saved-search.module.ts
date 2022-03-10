import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { BaseCommonModule } from 'shared/base.common.module';
import { NotificationModule } from 'shared/component/notification/notification.module';
import { SharedModule } from 'shared/shared.module';

@NgModule({
    declarations: [],
    imports: [
        BaseCommonModule,
        SharedModule,
        HttpClientModule,
        NotificationModule
    ],
    providers: [
    ]
})
export class SavedSearchModule {}