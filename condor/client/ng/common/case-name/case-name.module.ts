import { NgModule } from '@angular/core';
import { TreeViewModule } from '@progress/kendo-angular-treeview';
import { UploadsModule } from '@progress/kendo-angular-upload';
import { AjsUpgradedProviderModule } from 'ajs-upgraded-providers/ajs-upgraded-provider.module';
import { CaseHeaderModule } from 'cases/case-header/case-header.module';
import { NameHeaderModule } from 'names/name-header/name-header.module';
import { ButtonsModule } from 'shared/component/buttons/buttons.module';
import { DirectivesModule } from 'shared/directives/directives.module';
import { PipesModule } from 'shared/pipes/pipes.module';
import { SharedModule } from 'shared/shared.module';
import { AttachmentFileBrowserComponent } from '../attachments/attachment-maintenance/attachment-file-browser/attachement-file-browser.component';
import { AttachmentFileUploadComponent } from '../attachments/attachment-maintenance/attachment-file-upload/attachment-file-upload.component';
import { AttachmentFolderBrowserComponent } from '../attachments/attachment-maintenance/attachment-folder-browser/attachment-folder-browser.component';
import { AttachmentMaintenanceFormComponent } from '../attachments/attachment-maintenance/attachment-maintenance-form/attachment-maintenance-form.component';
import { AttachmentMaintenanceComponent } from '../attachments/attachment-maintenance/attachment-maintenance.component';
import { AttachmentModalService } from '../attachments/attachment-modal.service';
import { AttachmentsModalComponent } from '../attachments/attachments-modal/attachments-modal.component';
import { AttachmentsComponent } from '../attachments/attachments.component';
import { DmsModalComponent } from './dms-modal/dms-modal.component';
import { DmsDocumentComponent } from './dms/dms-documents/dms-documents.component';
import { DmsComponent } from './dms/dms.component';
import { DmsPersistenceService } from './dms/dms.persistence.service';
import { DmsService } from './dms/dms.service';
import { GenerateDocumentErrorsComponent } from './generate-document/generate-document-errors/generate-document-errors.component';
import { GenerateDocumentComponent } from './generate-document/generate-document.component';
import { GenerateDocumentService } from './generate-document/generate-document.service';

const components = [
   DmsComponent,
   DmsDocumentComponent,
   DmsModalComponent,
   AttachmentsComponent,
   AttachmentsModalComponent,
   AttachmentMaintenanceComponent,
   AttachmentFileBrowserComponent,
   AttachmentFolderBrowserComponent,
   AttachmentFileUploadComponent,
   GenerateDocumentComponent,
   GenerateDocumentErrorsComponent,
   AttachmentMaintenanceFormComponent
];

@NgModule({
   imports: [
      SharedModule,
      ButtonsModule,
      PipesModule,
      TreeViewModule,
      DirectivesModule,
      CaseHeaderModule,
      NameHeaderModule,
      UploadsModule,
      AjsUpgradedProviderModule
   ],
   exports: [
      ...components
   ],
   declarations: [
      ...components
   ],
   providers: [
      DmsService,
      DmsPersistenceService,
      GenerateDocumentService,
      AttachmentModalService
   ],
   entryComponents: [
      DmsComponent,
      DmsModalComponent
   ]
})
export class CaseViewNameViewModule { }