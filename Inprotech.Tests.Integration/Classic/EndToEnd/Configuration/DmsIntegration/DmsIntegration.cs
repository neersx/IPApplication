using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.Configuration.DmsIntegration
{
    [TestFixture]
    [Category(Categories.E2E)]
    public class DmsIntegration : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        public void Dms(BrowserType browserType)
        {
            using (var setup = new DmsIntegrationDb())
            {
                setup.WithDisabled().Setup();
            }

            var driver = BrowserProvider.Get(browserType);
            var popup = new CommonPopups(driver);
            SignIn(driver, "/#/configuration/dmsintegration");

            driver.With<DmsIntegrationPage>(page =>
            {
                Assert.True(page.IsSaveDisabled);

                page.PrivatePairChk.ClickWithTimeout();
                Assert.True(page.PrivatePairLocation.Element.Enabled);
                page.PrivatePairLocation.Input("abcd");
                page.PrivatePairLocation.Click();
                Assert.False(page.IsSaveDisabled);
                page.Save();
                driver.WaitForAngularWithTimeout();
                Assert.NotNull(popup.AlertModal);
                popup.AlertModal.Ok();

                page.PrivatePairLocation.Clear();
                Assert.NotNull(driver.FindElements(By.ClassName("cpa-icon-exclamation-triangle")).First());

                page.PrivatePairLocation.Input("C:/");
                page.Save();
                driver.WaitForAngularWithTimeout();
                popup.WaitForFlashAlert();
            });

            using (var setup = new DmsIntegrationDb())
            {
                setup.SetupDocument();
            }

            ReloadPage(driver);

            driver.With<DmsIntegrationPage>(page =>
            {
                Assert.False(page.MoveToDms.IsDisabled());
                page.PrivatePairLocation.Input("abcd");
                Assert.True(page.MoveToDms.IsDisabled());

                page.RevertButton.ClickWithTimeout();
                popup.DiscardChangesModal.Discard();

                Assert.True(page.AlertInfoIdle.Displayed);
                Assert.False(page.MoveToDms.IsDisabled());
                page.MoveToDms.Click();
                Assert.False(page.MoveToDmsExists);
                Assert.True(page.AlertInfoStarted.Displayed);
            });
            using (var setup = new DmsIntegrationDb())
            {
                setup.SetupJob();
            }

            ReloadPage(driver);
            driver.With<DmsIntegrationPage>(page =>
            {
                Assert.True(page.AlertInfoSuccess.Displayed);
                page.AlertInfoSuccessClose.Click();
            });
        }
    }
}