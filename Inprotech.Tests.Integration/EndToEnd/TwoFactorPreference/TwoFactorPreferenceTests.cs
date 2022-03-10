using System;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Net.Mail;
using System.Text;
using System.Threading;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Web.Security.TwoFactorAuth;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.Settings;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.TwoFactorPreference
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "Authentication2FAMode", "internal")]
    public class TwoFactorPreferenceTests : IntegrationTest
    {
        [TestCase(BrowserType.Chrome, Ignore = "To be reinstated in DR-64333")]
        [TestCase(BrowserType.FireFox, Ignore = "To be reinstated in DR-64333")]
        [TestCase(BrowserType.Ie)]
        public void SuccessfullyNavigatesThroughProcess(BrowserType browserType)
        {
            var internalUser = new Users().Create();
            var userKey = "2NLECSHQK2HUXL7UBDYBCNDC3Q======";
            var encryptedUserKey = "1KVY3SSHHk+cwHDvDP3xUsQVygTlPBdemXqDz9kHacBcgKymoM5FNOS+bcYZDHvl";

            DbSetup.Do(x =>
            {
                var u = x.DbContext.Set<User>().Single(_ => _.Id == internalUser.Id);

                x.Insert(new SettingValues
                {
                    CharacterValue = TwoFactorAuthVerify.Email,
                    User = u,
                    SettingId = KnownSettingIds.PreferredTwoFactorMode
                });

                x.Insert(new SettingValues
                {
                    CharacterValue = encryptedUserKey,
                    User = u,
                    SettingId = KnownSettingIds.AppTempSecretKey
                });

                x.Insert(new ConfigSetting
                {
                    Key = "InprotechServer.AppSettings." + KnownAppSettingsKeys.Authentication2FAMode,
                    Value = TwoFactorAuthenticationModeKeys.Internal
                });
            });

            var driver = BrowserProvider.Get(browserType);
            var currentFileSet = Directory.GetFiles(Runtime.MailPickupLocation, "*.eml");

            SignIn(driver, "/#/portal2", internalUser.Username, internalUser.Password, page =>
            {
                do
                {
                    Thread.Sleep(TimeSpan.FromMilliseconds(100));
                }
                while (currentFileSet.Count() == Directory.EnumerateFiles(Runtime.MailPickupLocation, "*.eml").Count());

                var message = new SimplePlainTextEmlParser()
                    .Parse(Directory.EnumerateFiles(Runtime.MailPickupLocation).Except(currentFileSet).FirstOrDefault());

                page.FormsAuthentication.Code.Input(message.Body.Substring(0, 6));

                page.FormsAuthentication.VerifyCode();
            });

            driver.With<QuickLinks>(slider =>
            {
                slider.Open("userinfo");

                driver.With<UserInfoPageObject>((page, popup) =>
                {
                    driver.WaitForAngular();
                    Assert.AreEqual(1, page.TwoFactorPreferenceDiv.Count, "Two Factor Preference Div Should Be Visible");
                    Assert.False(page.RadioUserPreferenceApp.IsChecked);
                    Assert.True(page.RadioUserPreferenceEmail.IsChecked);
                    page.ConfigureAppLink.Click();
                    driver.WaitForAngular();
                    Assert.AreEqual(0, page.TwoFactorPreferenceDiv.Count, "Two Factor Preference Div Should Be Hidden");

                    page.ProceedButton.Click();
                    driver.WaitForAngular();

                    page.ProceedButton.Click();
                    driver.WaitForAngular();

                    InprotechServer.CurrentUtcTime();
                    var codeToInput = new TwoFactorTotp().OneTimePassword(30, userKey).ComputeTotp();
                    page.VerifyCodeTextbox.SendKeys(codeToInput);
                    page.ProceedButton.Click();
                    driver.WaitForAngular();
                    Assert.AreEqual(1, page.TwoFactorPreferenceDiv.Count, "Two Factor Preference Div Should Be Visible");
                    Assert.GreaterOrEqual(1, page.SuccessMessage.Count, "Success Message Should Be Visible");
                    Assert.False(page.RadioUserPreferenceApp.IsDisabled, "Should allow authenticator app to be selected as default");
                    Assert.False(page.RadioUserPreferenceApp.IsChecked);
                    Assert.True(page.RadioUserPreferenceEmail.IsChecked);
                    page.RadioUserPreferenceApp.Click();
                    driver.WaitForAngular();
                    Assert.True(page.RadioUserPreferenceApp.IsChecked);
                    Assert.False(page.RadioUserPreferenceEmail.IsChecked);

                    page.RemoveConfigureLink.Click();
                    driver.WaitForAngular();

                    popup.ConfirmModal.Proceed();

                    Assert.AreEqual(1, page.TwoFactorPreferenceDiv.Count, "Two Factor Preference Div Should Be Visible");
                    Assert.GreaterOrEqual(1, page.SuccessMessage.Count, "Success Message Should Be Visible");
                    Assert.True(page.RadioUserPreferenceApp.IsDisabled, "Should not allow authenticator app to be selected as default");
                    Assert.False(page.RadioUserPreferenceApp.IsChecked);
                    Assert.True(page.RadioUserPreferenceEmail.IsChecked);
                });

                slider.Close();
            });
        }
    }

    public class UserInfoPageObject : PageObject
    {
        public UserInfoPageObject(NgWebDriver driver) : base(driver)
        {
            Container = Driver.FindElement(By.Id("user-info-and-two-factor"));
        }

        public NgWebElement VerifyCodeTextbox => Driver.FindElement(By.Id("txtTwoFactorCodeVerify"));
        public NgWebElement ProceedButton => Driver.FindElement(By.Id("btnTwoFactorAppConfigureProceed"));
        public NgWebElement ConfigureAppLink => Driver.FindElement(By.Id("lnkConfigureMobileAppTwoFactor"));
        public NgWebElement RemoveConfigureLink => Driver.FindElement(By.Id("lnkRemoveMobileAppTwoFactor"));
        public IpxRadioButton RadioUserPreferenceApp => new IpxRadioButton(Driver).ByValue("app");
        public IpxRadioButton RadioUserPreferenceEmail => new IpxRadioButton(Driver).ByValue("email");
        public ReadOnlyCollection<NgWebElement> TwoFactorPreferenceDiv => Driver.FindElements(By.CssSelector("#divSelectTwoFactorPreference"));
        public ReadOnlyCollection<NgWebElement> SuccessMessage => Driver.FindElements(By.CssSelector(".flash-alert"));
    }

    internal class SimplePlainTextEmlParser
    {
        public MailMessage Parse(string filePath)
        {
            var message = new MailMessage();
            var fileContent = File.ReadLines(filePath);
            var content = new StringBuilder();
            var startContent = false;
            foreach (var s in fileContent)
            {
                if (TryGetValue(s, "X-Sender: ", out var value))
                {
                    message.Sender = new MailAddress(value);
                    continue;
                }

                if (TryGetValue(s, "X-Receiver: ", out value))
                {
                    message.To.Add(new MailAddress(value));
                    continue;
                }

                if (TryGetValue(s, "Subject: ", out value))
                {
                    message.Subject = value;
                    continue;
                }

                if (!startContent && string.IsNullOrWhiteSpace(s))
                {
                    startContent = true;
                    continue;
                }

                if (startContent)
                {
                    content.Append(s.TrimEnd('='));
                }
            }

            message.Body = content.ToString().Replace("=0D=0A", $"{Environment.NewLine}");
            return message;
        }

        static bool TryGetValue(string context, string tokenToLookFor, out string value)
        {
            if (context.StartsWith(tokenToLookFor))
            {
                value = context.Remove(0, tokenToLookFor.Length).Trim();
                return true;
            }

            value = null;
            return false;
        }
    }
}