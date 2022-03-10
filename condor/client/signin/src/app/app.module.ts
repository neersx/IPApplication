import { CommonModule } from '@angular/common';
import { HttpClient, HttpClientModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { RouterModule, Routes } from '@angular/router';
import { TranslateLoader, TranslateModule } from '@ngx-translate/core';
import { TranslateHttpLoader } from '@ngx-translate/http-loader';

import { AppComponent } from './app.component';
import { ResetPasswordComponent } from './resetpassword/resetpassword.component';
import { ResetPasswordService } from './resetpassword/resetpassword.service';
import { SigninComponent } from './signin/signin.component';

const appRoutes: Routes = [
  { path: '', component: SigninComponent, pathMatch: 'full' },
  { path: 'reset-password', component: ResetPasswordComponent }
];

@NgModule({
  declarations: [
    AppComponent,
    SigninComponent,
    ResetPasswordComponent
  ],
  imports: [
    CommonModule,
    BrowserModule,
    FormsModule,
    ReactiveFormsModule,
    HttpClientModule,
    BrowserAnimationsModule,
    RouterModule.forRoot(appRoutes, { useHash: true }),
    TranslateModule.forRoot()
  ],
  providers: [ResetPasswordService],
  bootstrap: [AppComponent]
})
export class AppModule { }
