import { NgModule } from '@angular/core';
import { modalServiceProvider } from 'ajs-upgraded-providers/modal-service.provider';
import { BaseCommonModule } from 'shared/base.common.module';
import { IpxIeOnlyUrlComponent } from './ipx-ie-only-url.component';

@NgModule({
  imports: [BaseCommonModule],
  providers: [modalServiceProvider],
  declarations: [IpxIeOnlyUrlComponent],
  exports: [IpxIeOnlyUrlComponent]
})
export class IpxIeOnlyUrlModule { }
