using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using InprotechKaizen.Model.Profiles;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ReportingServicesIntegration
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ReportingServicesSetting : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyReportingServicesSetting(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/reporting-settings", "Administrator", "Administrator");
            var page = new ReportingServicesSettingPageObject(driver);
            driver.WaitForAngular();
            Assert.False(page.ApplyButton.Enabled);
            Assert.False(page.DiscardButton.Enabled);
            
            page.RootFolderTextField.Clear();
            page.BaseUrlTextField.Clear();
            page.MaxSizeTextField.Clear();
            page.TimeoutTextField.Clear();
            page.UsernameTextField.Clear();
            page.PasswordTextField.Clear();
            page.DomainTextField.Clear();

            page.RootFolderTextField.SendKeys("Inpro");
            page.BaseUrlTextField.SendKeys("http://localhost/reportserver");
            page.MaxSizeTextField.SendKeys("20");
            page.TimeoutTextField.SendKeys("10");
            page.UsernameTextField.SendKeys("ken");
            page.PasswordTextField.SendKeys("password");
            page.DomainTextField.SendKeys("int");
            Assert.True(page.ApplyButton.Enabled);
            Assert.True(page.DiscardButton.Enabled);
            page.ApplyButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            Assert.AreEqual("Your changes have been successfully saved.",page.MessageDiv.Text);
            Assert.False(page.ApplyButton.Enabled);
            Assert.False(page.DiscardButton.Enabled);

            page.RootFolderTextField.Clear();
            page.RootFolderTextField.SendKeys("new root folder");
            Assert.True(page.DiscardButton.Enabled);
            page.DiscardButton.ClickWithTimeout();
            
            var popups = new CommonPopups(driver);
            Assert.IsNotNull(popups.DiscardChangesModal, "confirm discard modal is present");
            popups.DiscardChangesModal.Discard();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("Inpro", page.RootFolderTextField.GetAttribute("value"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void TestConnection(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var settingString = @"5UYNwOPkrq6FJOUSs/SFLLHBzTPeYJe9RhXgPjsAhpbsd8ISQdT1M0hzsP/MiSkUU41uINBym3QRKfjv08Ftyow1m9IbvbDP/kzyfLmKvCgnCAXeIidnIWz9p01v6yF8DQuJ0RrgUcWFtciu7WL0AL1hVNqHhvhPMDaL5si0Tb0Y8hN8v6YrQJeGS95/VC959sMgcaAXas9dSTHMLW0AGh1+k5WK3gVsY81jru2X3bIeVLl7LlVZ1XfsbGX/jKl+";
                var setting = x.DbContext.Set<ExternalSettings>().SingleOrDefault(_ => _.ProviderName == "ReportingServicesSetting");

                if (setting != null)
                {
                    setting.Settings = settingString;
                    setting.IsComplete = true;
                }
                else
                {
                    x.DbContext.Set<ExternalSettings>().Add(new ExternalSettings("ReportingServicesSetting")
                    {
                        Settings = settingString,
                        IsComplete = true
                    });
                }

                x.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/reporting-settings", "Administrator", "Administrator");
            var page = new ReportingServicesSettingPageObject(driver);
            driver.WaitForAngular();
            page.TestButton.Click();
            Assert.AreEqual("Connection tested successfully.", page.SuccessElement.Text);
        }
    }
}