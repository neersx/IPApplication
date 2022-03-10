import { ChangeDetectionStrategy, ChangeDetectorRef, Component } from '@angular/core';
import { AppContextService } from 'core/app-context.service';

@Component({
  selector: 'ipx-case-attachment',
  templateUrl: './case-attachment.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CaseAttachmentComponent {
  case: { key: undefined };
    viewData = { isExternal: false, canMaintainAttachment: { canAdd: false, canEdit: false, canDelete: false }, baseType: 'case' };

  constructor(readonly appContext: AppContextService) {
    this.appContext.appContext$.subscribe(
      context => { this.viewData.isExternal = context.user.isExternal; });
  }
}
