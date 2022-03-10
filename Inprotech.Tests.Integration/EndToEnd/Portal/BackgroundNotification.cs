using System;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.GlobalCaseChange;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portal
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class BackgroundNotification : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyBackgroundNotification(BrowserType browserType)
        {
            var internalUser = new Users().Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2", internalUser.Username, internalUser.Password);

            var backgroundNotificationPageObject = new BackgroundNotificationPageObject(driver);
            var slider = new PageObjects.QuickLinks(driver);
            slider.Open("backgroundNotification");
            Assert.AreEqual("No results found.",backgroundNotificationPageObject.NoRecordFound.Text);
            Assert.AreEqual("color: white;", backgroundNotificationPageObject.NotificationIcon.GetAttribute("style"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void BackgroundNotificationPanel(BrowserType browserType)
        {
            var internalUser = new Users().Create();
            DbSetup.Do(x =>
            {
                var _case = new CaseBuilder(x.DbContext).Create(null, null, null, null, null, false);
                var backgroundProcess = new BackgroundProcess
                {
                    Id = Fixture.Integer(),
                    IdentityId = internalUser.Id,
                    ProcessType = BackgroundProcessType.GlobalCaseChange.ToString(),
                    Status = (int)StatusType.Completed,
                    StatusDate = DateTime.Now,
                    StatusInfo = string.Empty
                };
                var backgroundProcessOne = new BackgroundProcess
                {
                    Id = Fixture.Integer(),
                    IdentityId = internalUser.Id,
                    ProcessType = BackgroundProcessType.GlobalCaseChange.ToString(),
                    Status = (int)StatusType.Completed,
                    StatusDate = DateTime.Now,
                    StatusInfo = string.Empty
                };

                var globalCaseChangeResults = new GlobalCaseChangeResults()
                {
                    Id = backgroundProcess.Id,
                    CaseId = _case.Id,
                    OfficeUpdated = true,
                    CaseTextUpdated = true,
                    EntitySizeUpdated = false,
                    FamilyUpdated = false,
                    ProfitCentreCodeUpdated = false,
                    PurchaseOrderNoUpdated = true,
                    TitleUpdated = true,
                    TypeOfMarkUpdated = true,
                    IsPoliced = false
                };

                var globalCaseChangeResults1 = new GlobalCaseChangeResults()
                {
                    Id = backgroundProcessOne.Id,
                    CaseId = _case.Id,
                    OfficeUpdated = true,
                    CaseTextUpdated = true,
                    EntitySizeUpdated = false,
                    FamilyUpdated = false,
                    ProfitCentreCodeUpdated = false,
                    PurchaseOrderNoUpdated = true,
                    TitleUpdated = true,
                    TypeOfMarkUpdated = true,
                    IsPoliced = false
                };

                x.DbContext.Set<BackgroundProcess>().Add(backgroundProcess);
                x.DbContext.Set<BackgroundProcess>().Add(backgroundProcessOne);
                x.DbContext.Set<GlobalCaseChangeResults>().Add(globalCaseChangeResults);
                x.DbContext.Set<GlobalCaseChangeResults>().Add(globalCaseChangeResults1);
                x.DbContext.SaveChanges();
            });
            
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2", internalUser.Username, internalUser.Password);
            
            driver.WaitForAngularWithTimeout();
            var slider = new PageObjects.QuickLinks(driver);
           
            slider.Open("backgroundNotification");

            var backgroundNotificationPageObject = new BackgroundNotificationPageObject(driver);
            Assert.NotNull(backgroundNotificationPageObject.Grid);

            driver.Wait().ForTrue(() => backgroundNotificationPageObject.NotificationCount.Text.Equals( "2"));
            Assert.AreEqual("color: rgb(255, 194, 31);", backgroundNotificationPageObject.NotificationIcon.GetAttribute("style"));
            
            Assert.AreEqual(2,backgroundNotificationPageObject.Grid.Rows.Count);
            
            backgroundNotificationPageObject.RowLink(0).WithJs().Click();

            Assert.AreEqual( "Bulk Update Results", backgroundNotificationPageObject.PageTitle().Text);
            
            Assert.AreEqual("1", backgroundNotificationPageObject.RowCount().Text);
            slider.Open("backgroundNotification");

            backgroundNotificationPageObject.DeleteButton.Click();
            Assert.AreEqual("Are you sure you want to delete notification(s)?", backgroundNotificationPageObject.ConfirmDeleteMessage.Text);

            backgroundNotificationPageObject.CancelButton.Click();
            Assert.AreEqual(2, backgroundNotificationPageObject.Grid.Rows.Count);

            backgroundNotificationPageObject.DeleteButton.Click();
            backgroundNotificationPageObject.ConfirmDeleteButton.Click();
            Assert.AreEqual("Notification(s) successfully deleted.",backgroundNotificationPageObject.MessageDiv.Text);
            
            backgroundNotificationPageObject.DeleteAllButton.Click();
            backgroundNotificationPageObject.ConfirmDeleteButton.Click();
            Assert.AreEqual("Notification(s) successfully deleted.", backgroundNotificationPageObject.MessageDiv.Text );
            
            slider.Close();
        }
    }

    public class BackgroundNotificationPageObject : PageObject
    {
        public BackgroundNotificationPageObject(NgWebDriver driver) : base(driver)
        {
            Container = Driver.FindElement(By.Id("backgroundNotification"));
        }

        public KendoGrid Grid => new KendoGrid(Driver, "backgroundProcessGrid");

        public NgWebElement DeleteButton => Driver.FindElement(By.Id("delete"));

        public NgWebElement ConfirmDeleteMessage => Driver.FindElement(By.CssSelector(".modal-body p"));

        public NgWebElement CancelButton => Driver.FindElement(By.CssSelector(".modal-footer button:nth-of-type(1)"));

        public NgWebElement ConfirmDeleteButton => Driver.FindElement(By.CssSelector(".modal-footer button:nth-of-type(2)"));

        public NgWebElement DeleteAllButton => Driver.FindElement(By.Id("deleteAll"));

        public NgWebElement MessageDiv => Driver.FindElement(By.ClassName("flash_alert"));

        public NgWebElement NotificationCount => Driver.FindElement(By.XPath("//button[@id='backgroundNotification']/span"));

        public NgWebElement NoRecordFound => Driver.FindElement(By.XPath("//ipx-kendo-grid[@id='backgroundProcessGrid']/ipx-inline-alert/div/span"));

        public NgWebElement NotificationIcon => Driver.FindElement(By.XPath("//button[@id='backgroundNotification']/div"));
        
        public NgWebElement RowLink(int row)
        {
            return Grid.Rows[row].FindElement(By.TagName("a"));
        }

        public NgWebElement PageTitle()
        {
            return Driver.FindElement(By.XPath("//*[@id='quick-search-list']/ipx-sticky-header/div/ipx-page-title/div/h2/before-title/span[2]"));
        }

        public NgWebElement RowCount()
        {
            return Driver.FindElement(By.Id("caseSearchTotalRecords"));
        }
    }
}
