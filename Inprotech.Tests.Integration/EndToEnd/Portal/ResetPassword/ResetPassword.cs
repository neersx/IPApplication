using System;
using System.Linq;
using System.Web;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Portal.ResetPassword
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ResetPassword : IntegrationTest
    {
        [SetUp]
        public void RememberSiteControl()
        {
            DbSetup.Do(db =>
            {
                var siteControls = db.DbContext.Set<SiteControl>();

                _scInitialEnforcePasswordPolicy = siteControls.SingleOrDefault(_ => _.ControlId == SiteControls.EnforcePasswordPolicy)?.BooleanValue;
                _scInitialPasswordExpiryDuration = siteControls.SingleOrDefault(_ => _.ControlId == SiteControls.PasswordExpiryDuration)?.IntegerValue;
            });
        }

        [TearDown]
        public void ResetSiteControl()
        {
            DbSetup.Do(db =>
            {
                var siteControls = db.DbContext.Set<SiteControl>();

                var epp = siteControls.SingleOrDefault(_ => _.ControlId == SiteControls.EnforcePasswordPolicy);
                if (epp != null) epp.BooleanValue = _scInitialEnforcePasswordPolicy;

                var ppd = siteControls.SingleOrDefault(_ => _.ControlId == SiteControls.PasswordExpiryDuration);
                if (ppd != null) ppd.IntegerValue = _scInitialPasswordExpiryDuration;

                db.DbContext.SaveChanges();
            });
        }

        bool? _scInitialEnforcePasswordPolicy;
        int? _scInitialPasswordExpiryDuration;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyResetPassword(BrowserType browserType)
        {
            var internalUser = new Users().WithPermission(ApplicationTask.ChangeUserPassword).Create();
            var key = "4ZXMBTG62OHUBDU34YCL3JHRJE======";
            var token = "VEY3Kpn+7fN4SJL1/nJo7Qj9E/1EAU1Cc6DXezkMtl2wkR/nAVBmQn8CVQu8cF0d";

            DbSetup.Do(x =>
            {
                var u = x.DbContext.Set<User>().Single(_ => _.Id == internalUser.Id);
                var shouldEnforcePasswordPolicy = x.DbContext.Set<SiteControl>()
                                                   .Single(_ => _.ControlId == SiteControls.EnforcePasswordPolicy);
                shouldEnforcePasswordPolicy.BooleanValue = false;

                x.Insert(new SettingValues
                {
                    SettingId = KnownSettingIds.ResetPasswordSecretKey,
                    CharacterValue = key,
                    User = u
                });

                x.DbContext.SaveChanges();
            });

            var url = Env.RootUrl + "/signin/#/reset-password?token=" + HttpUtility.UrlEncode(token);
            var driver = BrowserProvider.Get(browserType);
            driver.Visit(url);
            var page = new ResetPasswordPageObject(driver);

            page.NewPasswordTextbox.Clear();
            page.ConfirmPasswordTextbox.Clear();
            page.SaveButton.Click();
            driver.WaitForAngular();
            Assert.AreEqual("New Password is required.", page.ErrorMessageDiv.Text);

            page.NewPasswordTextbox.SendKeys("password");
            page.ConfirmPasswordTextbox.Clear();
            page.SaveButton.Click();
            driver.WaitForAngular();
            Assert.AreEqual("Confirm Password is required.", page.ErrorMessageDiv.Text);

            page.NewPasswordTextbox.SendKeys("newpassword");
            page.ConfirmPasswordTextbox.SendKeys("confirmpassword");
            page.SaveButton.Click();
            driver.WaitForAngular();
            Assert.AreEqual("Passwords must match.", page.ErrorMessageDiv.Text);

            page.NewPasswordTextbox.Clear();
            page.ConfirmPasswordTextbox.Clear();
            page.NewPasswordTextbox.SendKeys("newpassword");
            page.ConfirmPasswordTextbox.SendKeys("newpassword");
            page.SaveButton.Click();
            driver.WaitForAngular();
            Assert.IsTrue(page.ForgotPasswordButtonOnSignIn.Displayed);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void SystemPromptsUserToChangePassword(BrowserType browserType)
        {
            var internalUser = new Users().WithPermission(ApplicationTask.ChangeUserPassword).Create();

            DbSetup.Do(x =>
            {
                var u = x.DbContext.Set<User>().Single(_ => _.Id == internalUser.Id);
                u.PasswordUpdatedDate = DateTime.Now.AddDays(-2);
                var shouldEnforcePasswordPolicy = x.DbContext.Set<SiteControl>()
                                                   .Single(_ => _.ControlId == SiteControls.EnforcePasswordPolicy);
                shouldEnforcePasswordPolicy.BooleanValue = true;
                var passwordExpiryDuration = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.PasswordExpiryDuration);
                passwordExpiryDuration.IntegerValue = 1;
                x.DbContext.SaveChanges();
            });
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/signin", internalUser.Username, internalUser.Password, page =>
            {
                var page2 = new ResetPasswordPageObject(driver);
                // Reset Password window should open
                Assert.IsTrue(new ResetPasswordPageObject(driver).NewPasswordTextbox.Displayed);
                Assert.IsTrue(page2.OldPasswordTextField.Displayed);
                Assert.IsTrue(page2.NewPasswordTextField.Displayed);
                Assert.IsTrue(page2.ConfirmPasswordTextField.Displayed);
                page2.SaveButton.Click();
                StringAssert.Contains("Old Password is required", page2.ErrorMessage.Text);
            });
        }
    }
}