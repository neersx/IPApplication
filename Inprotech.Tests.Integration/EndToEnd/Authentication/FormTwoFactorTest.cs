using System;
using System.IO;
using System.Linq;
using System.Net.Mail;
using System.Text;
using System.Threading;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Settings;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Authentication
{
    [TestFixture]
    [Category(Categories.E2E)]
    [ChangeAppSettings(AppliesTo.InprotechServer, "AuthenticationMode", "Forms,Windows,Sso", ConfigSettingsKey = "InprotechServer.AppSettings.AuthenticationMode")]
    [ChangeAppSettings(AppliesTo.InprotechServer, "Authentication2FAMode", "internal")]
    public class FormTwoFactorTest : IntegrationTest
    {
        [TearDown]
        public void TearDown()
        {
            using (var setup = new DbSetup())
            {
                var setting = setup.DbContext.Set<ConfigSetting>().Single(_ => _.Key.Equals(Authentication2FaModeKey));
                setting.Value = string.Empty;
                setup.DbContext.SaveChanges();
            }
        }

        const string Authentication2FaModeKey = "InprotechServer.AppSettings.Authentication2FAMode";

        [TestCase(BrowserType.Chrome, Ignore = "To be reinstated in DR-64333")]
        [TestCase(BrowserType.Ie, Ignore = "To be reinstated in DR-64333")]
        [TestCase(BrowserType.FireFox)]
        public void FormsTwoFactorLoginTest(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();
            using (var setup = new DbSetup())
            {
                const string enableForInternal = "Internal";
                var cs = setup.DbContext.Set<ConfigSetting>();
                var setting = cs.SingleOrDefault(_ => _.Key.Equals(Authentication2FaModeKey)) ??
                              setup.Insert(new ConfigSetting(Authentication2FaModeKey) { Value = enableForInternal });

                setting.Value = enableForInternal;
                setup.DbContext.SaveChanges();
            }

            var driver = BrowserProvider.Get(browserType);

            driver.Visit(Env.RootUrl + "/#/priorartold/search", false, true);
            Assert.True(driver.WithJs().GetUrl().Contains("priorart"), "despite going to protected page, should end up on login page");

            var currentFileSet = Directory.GetFiles(Runtime.MailPickupLocation, "*.eml");

            driver.With<AuthenticationPage>(page =>
            {
                page.FormsAuthentication.UserName.Input(user.Username);
                page.FormsAuthentication.Password.Input(user.Password);
                page.FormsAuthentication.SignIn();

                var currentUrl = driver.WithJs().GetUrl(withDelay: true);
                Assert.True(currentUrl.Contains("/apps/signin/#/"), "should go to the signin page code section");
            });

            do
            {
                Thread.Sleep(TimeSpan.FromMilliseconds(100));
            }
            while (currentFileSet.Count() == Directory.EnumerateFiles(Runtime.MailPickupLocation, "*.eml").Count());

            driver.With<AuthenticationPage>(page =>
            {
                var message = new SimplePlainTextEmlParser()
                    .Parse(Directory.EnumerateFiles(Runtime.MailPickupLocation).Except(currentFileSet).FirstOrDefault());

                var authCode = message.Body.Substring(0, 6);
                var emailContent = new DocItemHelper().GetEmailContent(KnownEmailDocItems.TwoFactor, authCode);
                Assert.AreEqual(emailContent.Subject.Trim(), message.Subject.Trim());
                Assert.IsTrue(message.Body.TextContains(emailContent.Footer));
                Assert.IsTrue(message.Body.TextContains(emailContent.Body));

                page.FormsAuthentication.Code.Input(authCode);

                page.FormsAuthentication.VerifyCode();

                Assert.True(driver.WithJs().GetUrl().Contains("priorart"), "sign in should succeed and lend on prior art");
            });
        }

        class SimplePlainTextEmlParser
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
}