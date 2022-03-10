import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { SharedModule } from 'shared/shared.module';
import { AttachmentBrowseSettingComponent } from './attachment-browse-setting/attachment-browse-setting.component';
import { AttachmentDmsIntegrationComponent } from './attachment-dms-integration/attachment-dms-integration.component';
import { AttachmentConfigurationService } from './attachments-configuration.service';
import { attachmentsConfigurationState } from './attachments-states';
import { AttachmentsComponent } from './attachments.component';
import { NetworkDriveMappingMaintenanceComponent } from './network-drive-mapping/network-drive-mapping-maintenance.component';
import { NetworkDriveMappingComponent } from './network-drive-mapping/network-drive-mapping.component';
import { AttachmentsStorageLocationsMaintenanceComponent } from './storage-locations/storage-locations-maintenance.component';
import { AttachmentsStorageLocationsComponent } from './storage-locations/storage-locations.component';

const components = [
  AttachmentsComponent,
  AttachmentsStorageLocationsComponent,
  AttachmentsStorageLocationsMaintenanceComponent,
  NetworkDriveMappingComponent,
  NetworkDriveMappingMaintenanceComponent,
  AttachmentDmsIntegrationComponent,
  AttachmentBrowseSettingComponent
];
@NgModule({
  imports: [
    CommonModule,
    SharedModule,
    UIRouterModule.forChild({ states: [attachmentsConfigurationState] })
  ],
  declarations: [
    ...components
  ],
  providers: [AttachmentConfigurationService]
})
export class AttachmentsModule { }
