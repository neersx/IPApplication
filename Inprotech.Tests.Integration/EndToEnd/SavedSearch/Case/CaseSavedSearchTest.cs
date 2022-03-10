using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Queries;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.SavedSearch.Case
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseSavedSearchTest : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CaseSavedSearchMenu(BrowserType browserType)
        {
            var data = new CaseSavedSearchDbSetup().Setup();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/portal2");

            var menuObjects = new CaseSavedSearchMenuObject(driver);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            Assert.IsTrue(menuObjects.GetMenuItem(data.query1.Name).Displayed);
            Assert.IsTrue(menuObjects.GetMenuItem(data.query2.Name).Displayed);
            Assert.IsTrue(driver.FindElement(By.CssSelector("menu-item[text='"+ data.query2.Name + "'] .cpa-icon-users")).Displayed);

            menuObjects.GetMenuItem(data.query1.Name).Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(data.query1.Name, driver.FindElement(By.CssSelector("span.search-term")).Text);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            var group1 = menuObjects.GetGroupMenuItem(((Query)data.query3).Group.GroupName);
            var group2 = menuObjects.GetGroupMenuItem(((Query) data.query5).Group.GroupName);

            Assert.IsTrue(group1.Displayed);
            Assert.IsTrue(group2.Displayed);
            Assert.IsTrue(group1.FindElement(By.ClassName("cpa-icon-chevron-down")).Displayed);

            group1.WithJs().Click();
            Assert.IsTrue(group1.FindElement(By.ClassName("cpa-icon-chevron-up")).Displayed);
            Assert.IsTrue(menuObjects.GetMenuItem(data.query3.Name).Displayed);
            Assert.IsTrue(driver.FindElement(By.CssSelector("menu-item[text='" + data.query3.Name + "'] .cpa-icon-users")).Displayed);
            
            menuObjects.GetMenuItem(data.query3.Name).Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(data.query3.Name, driver.FindElement(By.CssSelector("span.search-term")).Text);

            menuObjects.CaseSearchMenu.WithJs().Click();
            menuObjects.FilterCaseMenu.SendKeys("T");
            group1 = menuObjects.GetGroupMenuItem(((Query)data.query3).Group.GroupName);
            Assert.IsTrue(menuObjects.GetMenuItem(data.query1.Name).Displayed);
            Assert.IsTrue(menuObjects.GetMenuItem(data.query2.Name).Displayed);
            Assert.IsTrue(group1.Displayed);
            Assert.IsTrue(menuObjects.GetMenuItem(data.query4.Name).Displayed);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsEmpty(menuObjects.FilterCaseMenu.Text);
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CaseSavedSearchForExternalUser(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/portal2");

            var externalUser = new Users().CreateExternalUser();

            var data = new CaseSavedSearchDbSetup().Setup(externalUser.Id, true);

            SignIn(driver, "/#/case/search", externalUser.Username, externalUser.Password);

            var menuObjects = new CaseSavedSearchMenuObject(driver);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            Assert.IsTrue(menuObjects.GetMenuItem(data.query1.Name).Displayed);
            Assert.IsTrue(menuObjects.GetMenuItem(data.query2.Name).Displayed);
            Assert.IsTrue(driver.FindElement(By.CssSelector("menu-item[text='"+ data.query2.Name + "'] .cpa-icon-users")).Displayed);

            menuObjects.GetMenuItem(data.query1.Name).Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(data.query1.Name, driver.FindElement(By.CssSelector("span.search-term")).Text);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsTrue(menuObjects.CaseSubMenu.Displayed);
            var group1 = menuObjects.GetGroupMenuItem(((Query)data.query3).Group.GroupName);
            var group2 = menuObjects.GetGroupMenuItem(((Query) data.query5).Group.GroupName);

            Assert.IsTrue(group1.Displayed);
            Assert.IsTrue(group2.Displayed);
            Assert.IsTrue(group1.FindElement(By.ClassName("cpa-icon-chevron-down")).Displayed);

            group1.WithJs().Click();
            Assert.IsTrue(group1.FindElement(By.ClassName("cpa-icon-chevron-up")).Displayed);
            Assert.IsTrue(menuObjects.GetMenuItem(data.query3.Name).Displayed);
            Assert.IsTrue(driver.FindElement(By.CssSelector("menu-item[text='" + data.query3.Name + "'] .cpa-icon-users")).Displayed);
            
            menuObjects.GetMenuItem(data.query3.Name).Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(data.query3.Name, driver.FindElement(By.CssSelector("span.search-term")).Text);

            menuObjects.CaseSearchMenu.WithJs().Click();
            menuObjects.FilterCaseMenu.SendKeys("T");
            group1 = menuObjects.GetGroupMenuItem(((Query)data.query3).Group.GroupName);
            Assert.IsTrue(menuObjects.GetMenuItem(data.query1.Name).Displayed);
            Assert.IsTrue(menuObjects.GetMenuItem(data.query2.Name).Displayed);
            Assert.IsTrue(group1.Displayed);
            Assert.IsTrue(menuObjects.GetMenuItem(data.query4.Name).Displayed);

            menuObjects.CaseSearchMenu.WithJs().Click();
            Assert.IsEmpty(menuObjects.FilterCaseMenu.Text);
        }
    }
}
