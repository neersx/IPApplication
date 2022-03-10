using System;
using System.Security.Principal;
using System.Web;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Authentication
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "cpa.sso.iamUrl", "https://users.sso.ipendonet.com")]
    [ChangeAppSettings(AppliesTo.InprotechServer, "cpa.sso.serverUrl", "https://sso-staging.ipplatform.com")]
    [ChangeAppSettings(AppliesTo.InprotechServer, "cpa.sso.certificate", "MIIC6jCCAdKgAwIBAgIGAW2MzEhNMA0GCSqGSIb3DQEBDQUAMDYxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpDUEEgR2xvYmFsMRIwEAYDVQQDEwlKV1QgVG9rZW4wHhcNMTkxMDAyMTQwNzQxWhcNMjkwOTI5MTQwNzQxWjA2MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQ1BBIEdsb2JhbDESMBAGA1UEAxMJSldUIFRva2VuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnzrRQbfHAkMgclinEDjepGwelDAjD233Nrk7dqx2D2hfjhbumkULhYP0vjuXDcJ3cIpzOVcE4YDmKypcU27tNUDjGx66wxv0UxJ82xfH1JEup7zAdIeBrmpU8DtS02f9Mehi8qt3Iagh9NMrVo86uGskNi32IHXu6iljuKrV2ww51TezSMvY5SEAMYolQ/6yqy5+pHNhrQiU/xGswyry8W9VBxLOODmOcR8+a9ts4kfrwt92xBdroa670AHZg2th6vdfLhan+ef8wQIwKYk7Ros0glXJYqBWdXfu/L9lHy17D187J2IAJT/yuGiDL34Aml+1Xci9ICvCE0ANkHORZwIDAQABMA0GCSqGSIb3DQEBDQUAA4IBAQBmvt8ugIFejyiRSWSk3+nT1S1853GAi61l2hjkiQKulVDLJ5QCUDmtY5Wwu3/MKuLC0Q4N5MjGQs9KaVaubLWmiLsxmdEbbzVPc3u2FZfD6FiLmknrrLa2JQTp3WIqQ1WFshywDq68BQReSINabxzM0R76W//Vq9fM34zzr9tZifwFZJyDFZavLELEL2o+V6Yu7n29smF5gaANUaEMaNmqw92GR6pewFylY7A+57GvSMpU7RNZmc1P0YU3A4oG9dp92q+spBjEx/bj7S05+nllUznJf+TeDlngMJMJgryZncgdAavtY1Cyx1I5bk0nOdTqfBCsKM7eLwHZiv2pUyxC")]
    [ChangeAppSettings(AppliesTo.InprotechServer, "cpa.iam.proxy.server", "Custom")]
    [ChangeAppSettings(AppliesTo.InprotechServer, "cpa.iam.proxy.serverUrl", "https://users.sso.ipendonet.com")]
    [ChangeAppSettings(AppliesTo.InprotechServer, "AuthenticationMode", "Forms,Windows,Sso", ConfigSettingsKey = "InprotechServer.AppSettings.AuthenticationMode")]
    public class BrowserAuthenticationTest : IntegrationTest
    {
        const int Timeout = 120000;

        [TestCase(BrowserType.Chrome, Ignore = "Windows Login not working with container installation, find the requirements for NTLM or restrict this test to Physical machines")]
        [TestCase(BrowserType.Ie, Ignore = "Windows Login not working with container installation, find the requirements for NTLM or restrict this test to Physical machines")]
        public void WindowsLoginTest(BrowserType browserType)
        {
            new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create(WindowsIdentity.GetCurrent().Name);

            var driver = BrowserProvider.Get(browserType);

            driver.Visit(Env.RootUrl + "/#/priorartold/search", false, true);
            Assert.True(driver.WithJs().GetUrl().Contains("priorart"), "despite going to protected page, should end up on login page");

            driver.With<AuthenticationPage>(page =>
                                            {
                                                page.SignInWithWindows();
                                                Assert.True(driver.WithJs().GetUrl().Contains("priorart"), "should go to the page that was initially requested");
                                            });

            driver.With<AuthenticationPage>(page =>
                                            {
                                                page.Logout();
                                                Assert.True(driver.WithJs().GetUrl().Contains("/apps/signin"), "should go to login page");
                                            });

            driver.With<AuthenticationPage>(page =>
                                            {
                                                page.SignInWithWindows();
                                                driver.WaitForAngularWithTimeout();
                                                var currentUrl = driver.WithJs().GetUrl();
                                                Assert.True(currentUrl.Contains("/portal"), $"when no redirect url specified, should go to default home, but is '{currentUrl}' instead.");
                                                page.Logout();
                                            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void FormsLoginTest(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();

            var driver = BrowserProvider.Get(browserType);

            driver.Visit(Env.RootUrl + "/#/priorartold/search", false, true);
            Assert.True(driver.WithJs().GetUrl().Contains("priorart"), "despite going to protected page, should end up on login page");

            driver.With<AuthenticationPage>(page =>
                                            {
                                                page.FormsAuthentication.UserName.Input(user.Username);
                                                page.FormsAuthentication.Password.Input(user.Password);
                                                page.FormsAuthentication.SignIn();

                                                var currentUrl = driver.WithJs().GetUrl(withDelay: true);
                                                Assert.True(currentUrl.Contains("/#/priorartold/search"), $"should go to the page that was initially requested, but is '{currentUrl}' instead.");
                                            });

            driver.With<AuthenticationPage>(page =>
                                            {
                                                page.Logout();

                                                var currentUrl = driver.WithJs().GetUrl(withDelay: true);
                                                Assert.True(currentUrl.Contains("/apps/signin"), $"should go to login page, but is {currentUrl} instead.");
                                            });

            driver.With<AuthenticationPage>(page =>
                                            {
                                                page.FormsAuthentication.UserName.Input(user.Username);
                                                page.FormsAuthentication.Password.Input(user.Password);
                                                page.FormsAuthentication.SignIn();

                                                driver.WaitForAngularWithTimeout();
                                                var currentUrl = driver.WithJs().GetUrl(withDelay: true);
                                                Assert.True(currentUrl.Contains("/portal"), $"when no redirect url specified, should go to default home, but is '{currentUrl}' instead.");
                                            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie, Ignore = "Navigating from https://sso-staging.ipplatform.com back to http://localhost could not complete due to IE settings on E2E machines")]
        [TestCase(BrowserType.FireFox)]
        public void SsoLoginTestForLinkedUser(BrowserType browserType)
        {
            /*
             * This displays "The current webpage is trying to open a site on your intranet" in IE on agent machines.
             */

            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).CreateIpPlatformUser();

            LoginWithSso(browserType, user);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie, Ignore = "Navigating from https://sso-staging.ipplatform.com back to http://localhost could not complete due to IE settings on E2E machines")]
        [TestCase(BrowserType.FireFox)]
        public void SsoLoginTestForUserNotLinked(BrowserType browserType)
        {
            /*
             * This displays "The current webpage is trying to open a site on your intranet" in IE on agent machines.
             */

            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).CreateIpPlatformUser(false);

            LoginWithSso(browserType, user);
        }

        void LoginWithSso(BrowserType browserType, TestUser user)
        {
            const bool ignoreJsError = true;
            const bool withDelay = true;

            var driver = BrowserProvider.Get(browserType);

            driver.Visit(Env.RootUrl + "/#/priorartold/search", false, true);

            var currentUrl = driver.WithJs().GetUrl();
            Assert.True(currentUrl.Contains("/apps/signin"), $"despite going to protected page, should end up on login page, but is {currentUrl} instead.");

            var page = new AuthenticationPage(driver);
            page.SignInWithTheIpPlatform();
            driver.Wait().ForTrue(() => driver.WithJs().GetUrl(ignoreJsError).Contains("sso-staging.ipplatform.com/as/authorization.oauth2?client_id=inprotech"), Timeout);

            currentUrl = driver.WithJs().GetUrl(ignoreJsError, withDelay);
            Assert.True(currentUrl.Contains("priorart"), $"should have redirect page in resumeUri, but is {currentUrl} instead.");

            var sso = new SsoAuthentication(driver.WrappedDriver);
            sso.SignIn(user.Username, user.Password);

            driver.Wait().ForTrue(() => driver.WithJs().GetUrl(ignoreJsError).Contains("apps/#/priorartold/search"), Timeout);

            page.Logout();
            driver.Wait().ForTrue(() => driver.WithJs().GetUrl(ignoreJsError).Contains("sso-staging.ipplatform.com/ext/cloudlogout"), Timeout);

            currentUrl = driver.WithJs().GetUrl(ignoreJsError, withDelay);
            Assert.True(currentUrl.Contains(HttpUtility.UrlEncode("/apps/signin")), $"should have signin page in resumeUri, but is {currentUrl} instead.");
        }

        [TestCase(BrowserType.Chrome, Ignore = "Windows Login not working with container installation, find the requirements for NTLM or restrict this test to Physical machines")]
        public void AutoLoginTest(BrowserType browserType)
        {
            const bool ignoreJsError = true;
            const bool withDelay = true;

            var user = new Users().WithPermission(ApplicationTask.ConfigureDmsIntegration).CreateIpPlatformUser();

            var driver = BrowserProvider.Get(browserType);

            driver.Visit(Env.RootUrl + "/#/configuration/search", false, true);

            var currentUrl = driver.WithJs().GetUrl();
            Assert.True(currentUrl.Contains("/apps/signin"), $"despite going to protected page, should end up on login page, but is {currentUrl} instead.");

            var page = new AuthenticationPage(driver);
            page.SignInWithTheIpPlatform();
            driver.Wait().ForTrue(() => driver.WithJs().GetUrl(ignoreJsError).Contains("sso-staging.ipplatform.com/as/authorization.oauth2?client_id=inprotech"));

            currentUrl = driver.WithJs().GetUrl(ignoreJsError);
            Assert.True(currentUrl.Contains("configuration"), $"should have redirect page in resumeUri, but is {currentUrl} instead.");

            var sso = new SsoAuthentication(driver.WrappedDriver);
            sso.SignIn(user.Username, user.Password);

            driver.Wait().ForTrue(() => driver.WithJs().GetUrl(ignoreJsError).Contains("apps/#/configuration/search"), Timeout);

            driver.WrappedDriver.Url = Env.RootUrl + "/signin";
            driver.Wait().ForTrue(() => driver.WithJs().GetUrl(ignoreJsError).Contains("portal"), Timeout);

            page.Logout();

            currentUrl = driver.WithJs().GetUrl(ignoreJsError, withDelay);
            Assert.True(currentUrl.Contains("sso-staging.ipplatform.com/ext/cloudlogout"), $"should go to cloud logout page, but is {currentUrl} instead.");
            Assert.True(currentUrl.Contains("/apps/signin"), $"should have signin page in resumeUri, but is {currentUrl} instead.");

            new Users().WithPermission(ApplicationTask.ConfigureDmsIntegration).Create(WindowsIdentity.GetCurrent().Name);

            driver.WrappedDriver.Url = Env.RootUrl + "/signin";
            currentUrl = driver.WithJs().GetUrl(ignoreJsError, withDelay);
            Assert.True(currentUrl.Contains("signin"), $"Should not automatically log in after logout, but is {currentUrl} instead.");

            page.SignInWithWindows();

            currentUrl = driver.WithJs().GetUrl(ignoreJsError, withDelay);
            Assert.True(currentUrl.Contains("portal"), $"Log in using windows, but is {currentUrl} instead.");

            driver.WrappedDriver.Url = Env.RootUrl + "/signin";
            driver.Wait().ForTrue(() => driver.WithJs().GetUrl(ignoreJsError).Contains("portal"), Timeout);

            page.Logout();

            currentUrl = driver.WithJs().GetUrl(ignoreJsError, withDelay);
            Assert.True(currentUrl.Contains("/apps/signin"), $"should have signin page in resumeUri, but is {currentUrl} instead.");
        }
    }
}