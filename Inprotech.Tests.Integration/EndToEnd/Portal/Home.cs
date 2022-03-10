using System.Collections.ObjectModel;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Search.Case;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portal
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class Home : IntegrationTest
    {
        void ClickCaseSearchBuilder(CaseSearchPageObject searchPage)
        {
            searchPage.CaseSearchMenuItem().WithJs().Click();
            Assert.IsTrue(searchPage.CaseSubMenu.Displayed);
            searchPage.CaseSearchBuilder().WithJs().Click();
        }
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void SetCurrentPageAsHomePageTab(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");

            var searchPage = new CaseSearchPageObject(driver);
            ClickCaseSearchBuilder(searchPage);
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");

            var slider = new PageObjects.QuickLinks(driver);

            slider.Open("setAsHomePage");

            var home = new HomePageObject(driver);
            driver.WaitForAngular();
            home.HomeIcon.WithJs().Click();
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");
            driver.WaitForAngular();
            slider.Open("setAsHomePage");
            driver.WaitForAngular();
            home.HomeIcon.WithJs().Click();
            Assert.AreEqual("/portal2", driver.Location, "Should navigate to Recent Cases page");
        }
    }

    public class HomePageObject : PageObject
    {
        public HomePageObject(NgWebDriver driver) : base(driver)
        {
            Container = Driver.FindElement(By.Id("Home"));
        }

        public NgWebElement HomeIcon => FindElement(By.CssSelector("menu-item[text='Home'] .nav-label"));

        public NgWebElement CaseSearch => FindElement(By.CssSelector("a[translate='cases.caseSearch']"));

    }
}