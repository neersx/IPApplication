import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CarouselModule } from 'ngx-bootstrap/carousel';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { MultiFactorAuthenticationModule } from 'rightbarnav/userinfo/mfa/multi-factor-authentication.module';
import { SharedModule } from 'shared/shared.module';
import { BackgroundNotificationComponent } from './background-notification/background-notification.component';
import { BackgroundNotificationService } from './background-notification/background-notification.service';
import { GraphIntegrationService } from './background-notification/graph-integration.service';
import { CaseWebLinksComponent } from './caseweblinks/caseweblinks.component';
import { CookieDeclarationComponent } from './help/cookie-declaration/cookie-declaration.component';
import { HelpComponent } from './help/help.component';
import { HelpService } from './help/help.service';
import { ThirdPartySoftwareLicensesComponent } from './help/thirdpartysoftwarelicenses/thirdpartysoftwarelicenses.component';
import { HomePageService } from './homepage/homepage.service';
import { InternalCaseDetailsComponent } from './Internalcasedetails/internal-case-details.component';
import { InternalNameDetailsComponent } from './internalnamedetails/internal-name-details.component';
import { KeepOnTopNotesComponent } from './keepontopnotes/keep-on-top-notes.component';
import { KeyboardShortcutCheatSheetComponent } from './keyboardshortcutcheatsheet/keyboardshortcutcheatsheet.component';
import { LinksComponent } from './links/links.component';
import { LinkService } from './links/links.service';
import { RightBarNavComponent } from './rightbarnav.component';
import { RightBarNavService } from './rightbarnav.service';
import { RightBarNavLoaderService } from './rightbarnavloader.service';
import { TaskPlannerPreferencesComponent } from './taskplannerpreferences/task-planner-preferences.component';
import { TimeRecordingPreferencesComponent } from './time-recording-preferences/time-recording-preferences.component';
import { TimeRecordingPreferenceService } from './time-recording-preferences/time-recording-preferences.service';
import { ChangePasswordComponent } from './userinfo/changepassword/changepassword.component';
import { ChangePasswordService } from './userinfo/changepassword/changepassword.service';
import { UserInfoComponent } from './userinfo/userinfo.component';

@NgModule({
  declarations: [
    RightBarNavComponent,
    UserInfoComponent,
    HelpComponent,
    LinksComponent,
    CaseWebLinksComponent,
    InternalCaseDetailsComponent,
    KeyboardShortcutCheatSheetComponent,
    ThirdPartySoftwareLicensesComponent,
    CookieDeclarationComponent,
    ChangePasswordComponent,
    BackgroundNotificationComponent,
    TimeRecordingPreferencesComponent,
    InternalNameDetailsComponent,
    KeepOnTopNotesComponent,
    TaskPlannerPreferencesComponent
  ],
  imports: [
    CarouselModule.forRoot(),
    MultiFactorAuthenticationModule,
    CommonModule,
    HttpClientModule,
    FormsModule,
    SharedModule
  ],
  providers: [
    RightBarNavService,
    RightBarNavLoaderService,
    HelpService,
    LinkService,
    HomePageService,
    BsModalRef,
    ChangePasswordService,
    BackgroundNotificationService,
    TimeRecordingPreferenceService,
    GraphIntegrationService
  ],
  entryComponents: [
    UserInfoComponent,
    HelpComponent,
    LinksComponent,
    CaseWebLinksComponent,
    InternalCaseDetailsComponent,
    KeyboardShortcutCheatSheetComponent,
    ThirdPartySoftwareLicensesComponent,
    CookieDeclarationComponent,
    ChangePasswordComponent,
    BackgroundNotificationComponent,
    TimeRecordingPreferencesComponent,
    InternalNameDetailsComponent,
    KeepOnTopNotesComponent,
    TaskPlannerPreferencesComponent
  ]
})

export class RightBarModule { }
