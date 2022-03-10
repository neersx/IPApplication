using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Authentication;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration
{
    public abstract class IntegrationTest
    {
        readonly Dictionary<ChangeAppSettings, string> _updated = new Dictionary<ChangeAppSettings, string>();

        protected string SignIn(NgWebDriver driver, string url, string username = "internal", string password = "internal", Action<AuthenticationPage> afterSignIn = null)
        {
            const int initialPageLoadWaitTimeout = 500;
            const int numberOfRetries = 20;

            ExtendImplicitWaitForIeDuringSignIn(driver);

            driver.WrappedDriver.Url = Env.RootUrl + "/signin";

            driver.Manage().Window.Size = new Size(1920, 1200);

            new WebDriverWait(new SystemClock(), driver, TimeSpan.FromSeconds(120), TimeSpan.FromSeconds(1))
                .Until(ExpectedConditions.ElementIsVisible(By.Name("username")));
            driver.With<AuthenticationPage>(page =>
            {
                page.FormsAuthentication.UserName.Input(username);
                page.FormsAuthentication.Password.Input(password);
                page.FormsAuthentication.SignIn();
                driver.WaitForAngularWithTimeout(initialPageLoadWaitTimeout, numberOfRetries);
                afterSignIn?.Invoke(page);
            });

            driver.Visit(Env.RootUrl + url);

            Try.Do(() => driver.Manage().Timeouts().ImplicitWait = TimeSpan.FromSeconds(3));

            return driver.CurrentWindowHandle;
        }

        protected string OpenAnotherTab(NgWebDriver driver, string url, string username = "internal", string password = "internal", BrowserType browserType = BrowserType.Default)
        {
            driver.WithJs().ExecuteJavaScript<object>($"window.open()");
            driver.SwitchTo().Window(driver.WindowHandles.Last());
            switch (browserType)
            {
                case BrowserType.Chrome:
                case BrowserType.FireFox:
                case BrowserType.Default:
                    driver.Visit(Env.RootUrl + url);
                    break;
                case BrowserType.Ie:
                    SignIn(driver, url, username, password);
                    break;
            }

            return driver.CurrentWindowHandle;
        }

        static void ExtendImplicitWaitForIeDuringSignIn(NgWebDriver driver)
        {
            if (!driver.Is(BrowserType.Ie)) return;

            // Signin for IE takes time, this is moved from BrowserType.cs
            driver.Manage().Timeouts().ImplicitWait = TimeSpan.FromSeconds(10);
        }

        protected void ReloadPage(NgWebDriver driver, bool longWait = false)
        {
            if (!Try.Do(() => { driver.Navigate().Refresh(); }))
            {
                driver.WithJs().Reload(true);
            }

            if (!longWait)
                driver.WaitForAngular();
            else
                driver.WaitForAngularWithTimeout();
        }

        protected void ReloadPageWithNotification(NgWebDriver driver, bool longWait = false, bool confirm = true)
        {
            if (!Try.Do(() => { driver.Navigate().Refresh(); }))
            {
                driver.WithJs().Reload(true);
            }

            if (!longWait)
                driver.WaitForAngular();
            else
                driver.WaitForAngularWithTimeout();
        }

        [SetUp]
        public void BaseSetUp()
        {
            AutoDbCleaner.Cleanup();

            var rebuild = GetType().GetCustomAttributes(typeof(RebuildsIntegrationDatabase), true);
            if (rebuild.Any())
            {
                DatabaseRestore.SafeRebuildIntegrationDatabase();
            }

            var changeAppSettings = GetType().GetCustomAttributes(typeof(ChangeAppSettings), true);
            var currentClassMethodName = $"{GetType().Name} (set-up)";

            foreach (var settings in changeAppSettings.Cast<ChangeAppSettings>())
            {
                _updated[settings] = SettingsModifier.UpdateSetting(settings.AppliesTo, settings.Key, settings.Value, settings.ConfigSettingsKey, currentClassMethodName);
            }
        }

        [TearDown]
        public void BaseCleanup()
        {
            var currentClassMethodName = $"{GetType().Name} (clean-up)";

            foreach (var updated in _updated)
            {
                SettingsModifier.UpdateSetting(updated.Key.AppliesTo, updated.Key.Key, updated.Value, updated.Key.ConfigSettingsKey, currentClassMethodName);
            }

            BrowserProvider.CloseBrowsers();
        }
    }

    [ChangeAppSettings(AppliesTo.InprotechServer, "cpa.sso.iamUrl", "https://users.sso-staging.ipplatform.com")]
    [ChangeAppSettings(AppliesTo.InprotechServer, "cpa.sso.serverUrl", "https://sso-staging.ipplatform.com")]
    [ChangeAppSettings(AppliesTo.InprotechServer, "cpa.sso.certificate", "MIIC6jCCAdKgAwIBAgIGAW2MzEhNMA0GCSqGSIb3DQEBDQUAMDYxCzAJBgNVBAYTAlVTMRMwEQYDVQQKEwpDUEEgR2xvYmFsMRIwEAYDVQQDEwlKV1QgVG9rZW4wHhcNMTkxMDAyMTQwNzQxWhcNMjkwOTI5MTQwNzQxWjA2MQswCQYDVQQGEwJVUzETMBEGA1UEChMKQ1BBIEdsb2JhbDESMBAGA1UEAxMJSldUIFRva2VuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnzrRQbfHAkMgclinEDjepGwelDAjD233Nrk7dqx2D2hfjhbumkULhYP0vjuXDcJ3cIpzOVcE4YDmKypcU27tNUDjGx66wxv0UxJ82xfH1JEup7zAdIeBrmpU8DtS02f9Mehi8qt3Iagh9NMrVo86uGskNi32IHXu6iljuKrV2ww51TezSMvY5SEAMYolQ/6yqy5+pHNhrQiU/xGswyry8W9VBxLOODmOcR8+a9ts4kfrwt92xBdroa670AHZg2th6vdfLhan+ef8wQIwKYk7Ros0glXJYqBWdXfu/L9lHy17D187J2IAJT/yuGiDL34Aml+1Xci9ICvCE0ANkHORZwIDAQABMA0GCSqGSIb3DQEBDQUAA4IBAQBmvt8ugIFejyiRSWSk3+nT1S1853GAi61l2hjkiQKulVDLJ5QCUDmtY5Wwu3/MKuLC0Q4N5MjGQs9KaVaubLWmiLsxmdEbbzVPc3u2FZfD6FiLmknrrLa2JQTp3WIqQ1WFshywDq68BQReSINabxzM0R76W//Vq9fM34zzr9tZifwFZJyDFZavLELEL2o+V6Yu7n29smF5gaANUaEMaNmqw92GR6pewFylY7A+57GvSMpU7RNZmc1P0YU3A4oG9dp92q+spBjEx/bj7S05+nllUznJf+TeDlngMJMJgryZncgdAavtY1Cyx1I5bk0nOdTqfBCsKM7eLwHZiv2pUyxC")]
    [ChangeAppSettings(AppliesTo.InprotechServer, "cpa.iam.proxy.server", "Custom")]
    [ChangeAppSettings(AppliesTo.InprotechServer, "cpa.iam.proxy.serverUrl", "https://users.sso-staging.ipplatform.com")]
    [ChangeAppSettings(AppliesTo.InprotechServer, "AuthenticationMode", "Forms,Windows,Sso")]
    public class IppIntegrationTest : IntegrationTest
    {
        const bool IgnoreJsError = true;

        const int Timeout = 120000;

        protected static void SignInToThePlatform(NgWebDriver driver, string caseUrl, TestUser user)
        {
            driver.Visit(caseUrl, false, true);

            var page = new AuthenticationPage(driver);
            page.SignInWithTheIpPlatform();
            driver.Wait().ForTrue(() => driver.WithJs().GetUrl(IgnoreJsError).Contains("sso-staging.ipplatform.com/as/authorization.oauth2?client_id=inprotech"), Timeout);

            var sso = new SsoAuthentication(driver.WrappedDriver);
            sso.SignIn(user.Username, user.Password);

            driver.Wait().ForTrue(() => driver.WithJs().GetUrl(IgnoreJsError).Contains(caseUrl), Timeout);
        }

        protected static void SignOutOfThePlatform(NgWebDriver driver)
        {
            new AuthenticationPage(driver).Logout();
            driver.Wait().ForTrue(() => driver.WithJs().GetUrl(IgnoreJsError).Contains("sso-staging.ipplatform.com/ext/cloudlogout"), Timeout);
        }
    }
}