using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Components
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class DetailPageTest : IntegrationTest
    {
        const string PageTitle = "Detail Page Tests";
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox, Ignore = "Alert is not showing in Firefox")]
        public void DiscardChangesAfterUnsavedChangesWarning(BrowserType browserType)
        {
            var data = DbSetup.Do(_ =>
                                  {
                                      var criteria = new CriteriaBuilder(_.DbContext).Create();

                                      return new
                                             {
                                                 criteria.Description
                                             };
                                  });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/detailpage");

            var page = new SamplePage(driver);
            Assert.AreEqual(PageTitle, page.Title);

            page.Picklist.EnterAndSelect(data.Description);

            driver.WithJs().ReloadPage();
            driver.Wait().ForAlert();

            var alert = driver.SwitchTo().Alert();
            alert.Accept();

            driver.WaitForAngularWithTimeout();

            driver.Wait().ForExists(By.Id("picklist")); // page is reloading
            Assert.AreNotEqual(data.Description, page.Picklist.InputValue, "Any changes are discarded");
        }
    }

    internal class SamplePage : PageObject
    {
        public SamplePage(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public PickList Picklist => new PickList(Driver).ById("picklist");

        public string Title => Driver.FindElement(By.TagName("h2")).Text;
    }
}