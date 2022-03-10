using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Queries;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.CaseSearchColumn
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ColumnSearchCases : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _columnSearchDbSetup = new ColumnSearchCaseDbSetup();
            _scenario = _columnSearchDbSetup.Prepare();
        }

        ColumnSearchCaseDbSetup _columnSearchDbSetup;
        ColumnSearchCaseDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyRefreshButtonFunctionalityOnPresentationScreen(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");
            var page = new ColumnSearchPageObject(driver);
            page.PresentationLink.ClickWithTimeout();
            Assert.IsTrue(page.MaintainColumnButton.Displayed);
            page.AvailableColumnInputField.Text = "e2e column";
            var parentWindowHandler = driver.CurrentWindowHandle;
            page.MaintainColumnButton.ClickWithTimeout();
            foreach (var winHandle in driver.WindowHandles)
                driver.SwitchTo().Window(winHandle);
            driver.WaitForGridLoader();
            page.AddSearchColumnButton.ClickWithTimeout();
            page.DisplayName.SendKeys("e2e column");
            page.ColumnNamePicklist.EnterExactSelectAndBlur("BilledTotal");
            page.DisplayName.Click();
            page.SaveColumnButton.ClickWithTimeout();
            driver.Close();
            driver.SwitchTo().Window(parentWindowHandler);
            Assert.IsTrue(page.RefreshButton.Displayed);
            page.RefreshButton.Click();
            Assert.IsTrue(page.NewColumn.Displayed);
        }
    }
}
