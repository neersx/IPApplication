using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portal.ChangePassword
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ChangePassword : IntegrationTest
    {
        [SetUp]
        public void RememberSiteControl()
        {
            DbSetup.Do(db =>
            {
                var siteControls = db.DbContext.Set<SiteControl>();

                _scInitialEnforcePasswordPolicy = siteControls.SingleOrDefault(_ => _.ControlId == SiteControls.EnforcePasswordPolicy)?.BooleanValue;
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

                db.DbContext.SaveChanges();
            });
        }

        bool? _scInitialEnforcePasswordPolicy;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyChangePassword(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var shouldEnforcePasswordPolicy = x.DbContext.Set<SiteControl>()
                                           .Single(_ => _.ControlId == SiteControls.EnforcePasswordPolicy);
                shouldEnforcePasswordPolicy.BooleanValue = true;
                x.DbContext.SaveChanges();
            });

            var internalUser = new Users().Create();
            var driver = OpenChangePasswordModal(browserType,internalUser);

            var modal = new ChangePasswordPageObject(driver);
            modal.OldPasswordTextbox.SendKeys(internalUser.Password + "1");
            modal.NewPasswordTextbox.SendKeys("123");
            modal.ConfirmNewPasswordTextbox.SendKeys("123");
            modal.SubmitButton.Click();
            Assert.IsTrue(modal.ErrorMessageDiv.Displayed);
            Assert.AreEqual("The old password is incorrect. Please re-enter.",modal.ErrorMessageDiv.Text);

            modal.OldPasswordTextbox.Clear();
            modal.NewPasswordTextbox.Clear();
            modal.ConfirmNewPasswordTextbox.Clear();
            modal.OldPasswordTextbox.Click();
            modal.NewPasswordTextbox.Click();
            modal.ConfirmNewPasswordTextbox.Click();
            Assert.IsTrue(modal.SubmitButton.IsDisabled());
            Assert.IsTrue(new TextField(driver, "oldPassword").HasError, "Required field");
            Assert.IsTrue(new TextField(driver, "newPassword").HasError, "Required field");
            Assert.IsTrue(new TextField(driver, "confirmNewPassword").HasError, "Required field");

            modal.OldPasswordTextbox.SendKeys(internalUser.Password);
            modal.NewPasswordTextbox.SendKeys("newpassword");
            modal.ConfirmNewPasswordTextbox.SendKeys("confirmpassword");
            modal.SubmitButton.Click();
            Assert.IsTrue(new TextField(driver, "confirmNewPassword").HasError, "The two passwords do not match");

            modal.OldPasswordTextbox.Clear();
            modal.NewPasswordTextbox.Clear();
            modal.ConfirmNewPasswordTextbox.Clear();
            modal.OldPasswordTextbox.SendKeys(internalUser.Password);
            modal.NewPasswordTextbox.SendKeys("123");
            modal.ConfirmNewPasswordTextbox.SendKeys("123");
            modal.SubmitButton.Click();
            Assert.IsTrue(modal.ErrorMessageDiv.Displayed);
            
            modal.NewPasswordTextbox.Clear();
            modal.ConfirmNewPasswordTextbox.Clear();
            modal.NewPasswordTextbox.SendKeys(internalUser.Username);
            modal.ConfirmNewPasswordTextbox.SendKeys(internalUser.Username);
            modal.SubmitButton.Click();
            Assert.IsTrue(modal.ErrorMessageDiv.Displayed);
            
            modal.NewPasswordTextbox.Clear();
            modal.ConfirmNewPasswordTextbox.Clear();
            modal.NewPasswordTextbox.SendKeys("Test@123");
            modal.ConfirmNewPasswordTextbox.SendKeys("Test@123");
            modal.SubmitButton.Click();
            var popup = new CommonPopups(driver);
            Assert.IsTrue(popup.FlashAlertIsDisplayed());
        }
        
        private NgWebDriver OpenChangePasswordModal(BrowserType browserType,TestUser internalUser)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2", internalUser.Username, internalUser.Password);

            var slider = new PageObjects.QuickLinks(driver);

            slider.Open("userinfo");

            var userInfoSlideOut = new UserInfoPageObject(driver);

            userInfoSlideOut.ChangePasswordButton.Click();
            return driver;
        }
    }
}