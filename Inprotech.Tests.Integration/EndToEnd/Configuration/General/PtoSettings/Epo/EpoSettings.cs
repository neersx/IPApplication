using Inprotech.Tests.Integration.PageObjects;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.PtoSettings.Epo
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.IntegrationServer, "EpoAuthUrl", "https://ops.epo.org/3.2/auth/accesstoken")]
    public class EpoSettings : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void IncorrectKeysAreNotSaved(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            using (var dbSetup = new EpoSettingDbSetup())
            {
                dbSetup.EnsureEmptyConfiguration();
            }

            SignIn(driver, "/#/pto-settings/epo");
            driver.With<EpoSettingsPageObject>((epoSettings, popup) =>
            {
                Assert.IsEmpty(epoSettings.ConsumerKey.Text);
                Assert.IsEmpty(epoSettings.PrivateKey.Text);

                epoSettings.ConsumerKey.Text = "SomeKey";
                epoSettings.PrivateKey.Text = "Some Secret";

                epoSettings.TestSettings();

                Assert.True(epoSettings.IsTestDone);
                Assert.True(epoSettings.TestIsUnSuccessful);

                epoSettings.SaveButton.Click();

                Assert.True(popup.AlertModal.Modal.Displayed);
                popup.AlertModal.Ok();

                //https://github.com/mozilla/geckodriver/issues/1151
                epoSettings.RevertButton.Click(); //edit mode discard
                epoSettings.Discard(); // discard confirm.
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CorrectKeysAreSaved(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/pto-settings/epo");

            driver.With<EpoSettingsPageObject>((epoSettings, popup) =>
            {
                epoSettings.ConsumerKey.Text = EpoKeys.ConsumerKey;
                epoSettings.PrivateKey.Text = EpoKeys.PrivateKey;

                epoSettings.SaveButton.Click();
                popup.WaitForFlashAlert();

                epoSettings.TestSettings();
                Assert.True(epoSettings.IsTestDone);
                Assert.True(epoSettings.TestIsSuccessful);
            });

            driver.Navigate().Refresh();

            driver.With<EpoSettingsPageObject>(epoSettings =>
            {
                Assert.AreEqual(EpoKeys.ConsumerKey.Length, epoSettings.ConsumerKey.Text.Length);
                Assert.AreEqual(EpoKeys.PrivateKey.Length, epoSettings.PrivateKey.Text.Length);

                //Text on screen is masked. Hence the actual text should not be same as in DB
                Assert.AreNotEqual(EpoKeys.ConsumerKey, epoSettings.ConsumerKey.Text);
                Assert.AreNotEqual(EpoKeys.PrivateKey, epoSettings.PrivateKey.Text);
            });
        }
    }
}