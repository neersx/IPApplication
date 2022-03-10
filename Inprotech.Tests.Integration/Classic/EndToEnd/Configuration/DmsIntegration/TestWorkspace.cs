using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms;
using Inprotech.Tests.Integration.PageObjects;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;
using OpenQA.Selenium;
using System.Linq;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.Configuration.DmsIntegration
{
    [TestFixture]
    [Category(Categories.E2E)]
    public class TestWorkspace : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        public void TestCaseWorkspace(BrowserType browserType)
        {
            new DocumentManagementDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);

            using (var x = new DbSetup())
            {
                var caseSearch = x.DbContext.Set<SiteControl>().First(_ => _.ControlId == SiteControls.DMSCaseSearchDocItem);
                caseSearch.StringValue = string.Empty;

                x.DbContext.SaveChanges();
            }

            SignIn(driver, "/#/configuration/dmsintegration");

            driver.With<DmsIntegrationPage>(page =>
            {
                var databaseTopic = new DmsIntegrationPage.DatabaseTopic(driver);
                var workSpaceTopic = new DmsIntegrationPage.WorkSpaceTopic(driver);

                workSpaceTopic.SearchField.Input.SelectByIndex(0);
                workSpaceTopic.SubClass.Input.SendKeys("Subclass");
                driver.WaitForAngular();
                databaseTopic.TestWorkspaceButton(driver, "testCaseWorkspace").Click();
                page.WorkspaceCaseRef.EnterAndSelect("001");
                driver.WaitForAngular();

                page.WorkspaceTestButton(driver).Click();
                Assert.NotNull(page.FindElement(By.XPath("//h3[contains(text(),'Search Parameter(s)')]")));
                Assert.NotNull(page.FindElement(By.XPath("//span[contains(text(),'001234')]")));
                Assert.NotNull(page.FindElement(By.XPath("//div[@id='searchParams']//div//div//div//span[contains(text(),'nameView')]")));
                Assert.NotNull(page.FindElement(By.XPath("//h3[contains(text(),'Result(s)')]")));
                Assert.AreEqual(page.FindElement(By.XPath("//div[@id='results']//div[1]//div[1]//div[1]//span[1]")).Text, "Case Workspace");
                Assert.AreEqual(page.FindElement(By.XPath("//div[@id='results']//div[1]//div[1]//div[1]//span[2]")).Text, ": 1001.001 - Microsoft vs. U.S. Department of Justice");
                Assert.AreEqual(page.FindElement(By.XPath("//div[@id='results']//div[2]//div[1]//div[1]//span[2]")).Text, ": Workfff");
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        public void TestNameWorkspace(BrowserType browserType)
        {
            new DocumentManagementDbSetup().Setup();
            var driver = BrowserProvider.Get(browserType);

            using (var x = new DbSetup())
            {
                var caseSearch = x.DbContext.Set<SiteControl>().First(_ => _.ControlId == SiteControls.DMSCaseSearchDocItem);
                caseSearch.StringValue = string.Empty;

                x.DbContext.SaveChanges();
            }

            SignIn(driver, "/#/configuration/dmsintegration");

            driver.With<DmsIntegrationPage>(page =>
            {
                var databaseTopic = new DmsIntegrationPage.DatabaseTopic(driver);
                var workSpaceTopic = new DmsIntegrationPage.WorkSpaceTopic(driver);

                workSpaceTopic.SearchField.Input.SelectByIndex(0);
                driver.WaitForAngular();
                databaseTopic.TestWorkspaceButton(driver, "testNameWorkspace").Click();
                page.WorkspaceNameRef.EnterAndSelect("abcd");
                driver.WaitForAngular();

                page.WorkspaceTestButton(driver).Click();
                Assert.NotNull(page.FindElement(By.XPath("//h3[contains(text(),'Search Parameter(s)')]")));
                Assert.NotNull(page.FindElement(By.XPath("//span[contains(text(),'ABCD')]")));
                Assert.NotNull(page.FindElement(By.XPath("//div[@id='searchParams']//div//div//div//span[contains(text(),'nameView')]")));
                Assert.NotNull(page.FindElement(By.XPath("//h3[contains(text(),'Result(s)')]")));
                Assert.AreEqual(page.FindElement(By.XPath("//div[@id='results']//div[1]//div[1]//div[1]//span[1]")).Text, "Name Workspace");
                Assert.AreEqual(page.FindElement(By.XPath("//div[@id='results']//div[1]//div[1]//div[1]//span[2]")).Text, " (Instructor)");
            });
        }
    }
}