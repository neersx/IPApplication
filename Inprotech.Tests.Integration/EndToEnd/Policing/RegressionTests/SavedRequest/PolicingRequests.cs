using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.SavedRequest
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestType(TestTypes.Regression)]
    public class PolicingRequests : IntegrationTest
    {
        const string IpWhatWillBePoliced = "ip_WhatWillBePoliced";
        [TearDown]
        public void RestoreStoredProcedure()
        {
            DbSetup.Do(x => x.DbContext.RestoreStoredProcedureFromBackup(IpWhatWillBePoliced));
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CalculateAffectedCases(BrowserType browserType)
        {
            TestUser loginUser;
            var driver = BrowserProvider.Get(browserType);
            var common = new CommonPopups(driver);
            var affectedCasesMessageSelector = By.CssSelector("span[translate='policing.request.maintenance.runRequest.affectedCases']");
            var affectedCasesSaveRequiredMessageSelector = By.CssSelector("span[translate='policing.request.maintenance.runRequest.pendingChanges']");

            using (var setup = new RequestsDbSetup())
            {
                setup.WithDefaultPolicingRequest();

                loginUser = setup
                    .Users
                    .WithPermission(ApplicationTask.PolicingAdministration)
                    .WithPermission(ApplicationTask.MaintainPolicingRequest)
                    .Create();
            }

            SignIn(driver, "/#/policing-saved-requests", loginUser.Username, loginUser.Password);

            var page = new SavedRequestsPageObject(driver);
            page.Add().ClickWithTimeout();

            UnsavedRunNow(page, common);

            page.MaintenanceModal.Discard.ClickWithTimeout();

            //Open first record for edit
            page.FirstTitleLink.ClickWithTimeout();

            driver.Wait().ForVisible(affectedCasesMessageSelector);

            page.MaintenanceModal.Title().Clear();
            page.MaintenanceModal.Title().SendKeys("1A a new title" + RandomString.Next(6));
            page.MaintenanceModal.Notes().SendKeys("test");

            UnsavedRunNow(page, common);

            page.MaintenanceModal.Save.ClickWithTimeout();
            Assert.NotNull(common.FlashAlert());
            
            page.MaintenanceModal.Attributes.CaseReference.EnterAndSelect("test");

            UnsavedRunNow(page,common);

            driver.Wait().ForVisible(affectedCasesSaveRequiredMessageSelector);

            page.MaintenanceModal.Save.ClickWithTimeout();

            TestFeatureNotAvailable(driver, page);

        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DatesCalculation(BrowserType browserType)
        {
            TestUser loginUser;
            var driver = BrowserProvider.Get(browserType);

            using (var setup = new RequestsDbSetup())
            {
                loginUser = setup.Users
                                 .WithPermission(ApplicationTask.PolicingAdministration)
                                 .WithPermission(ApplicationTask.MaintainPolicingRequest)
                                 .Create();

                setup.DbContext.RenameStoredProcedureAsBackup(IpWhatWillBePoliced);
            }

            SignIn(driver, "/#/policing-saved-requests", loginUser.Username, loginUser.Password);

            driver.With<SavedRequestsPageObject>
                ((page, popups) =>
                 {
                     page.Add().ClickWithTimeout();

                     page.MaintenanceModal.Title().Clear();
                     page.MaintenanceModal.Title().SendKeys("A new request");

                     page.MaintenanceModal.StartDate().Input.SendKeys("23-Sep-2016"); //Friday
                     page.MaintenanceModal.EndDate().Input.SendKeys("29-Sep-2016");

                     page.MaintenanceModal.Notes().SendKeys("t");

                     driver.WaitForAngularWithTimeout();

                     Assert.AreEqual("26-Sep-2016", page.MaintenanceModal.DateLetters().Input.Value(), "After Friday the next letters date should be Monday");
                     Assert.AreEqual("7", page.MaintenanceModal.ForDays().Value());

                     page.MaintenanceModal.ForDays().Clear();
                     page.MaintenanceModal.ForDays().SendKeys("10");
                     page.MaintenanceModal.Notes().SendKeys("e");

                     Assert.AreEqual("02-Oct-2016", page.MaintenanceModal.EndDate().Input.Value());

                     page.MaintenanceModal.StartDate().Input.Clear();
                     page.MaintenanceModal.ForDays().Clear();
                     page.MaintenanceModal.ForDays().SendKeys("11");
                     page.MaintenanceModal.Notes().SendKeys("s");

                     Assert.AreEqual("22-Sep-2016", page.MaintenanceModal.StartDate().Input.Value());

                     page.MaintenanceModal.ForDays().Clear();
                     page.MaintenanceModal.ForDays().SendKeys("-5");
                     page.MaintenanceModal.Notes().SendKeys("t");

                     Assert.AreEqual("22-Sep-2016", page.MaintenanceModal.StartDate().Input.Value());
                 });
        }

        static void UnsavedRunNow(SavedRequestsPageObject page, CommonPopups common)
        {
            page.MaintenanceModal.RunNow.Element.WithJs().Click();

            var script = "return $('p[translate=\"policing.request.maintenance.runRequest.saveRequired\"]').length == 1";

            Assert.True(page.Driver.WrappedDriver.ExecuteJavaScript<bool>(script), "Prompt to save request before calculating affected cases if new request");

            common.InfoModal.Ok();
        }

        void TestFeatureNotAvailable(NgWebDriver driver, SavedRequestsPageObject page)
        {
            var common = new CommonPopups(driver);
            var affectedCasesMessageSelector = By.CssSelector("span[translate='policing.request.maintenance.runRequest.affectedCases']");
            var affectedCasesSaveRequiredMessageSelector = By.CssSelector("span[translate='policing.request.maintenance.runRequest.pendingChanges']");
            using (var setup = new RequestsDbSetup())
            {
                setup.DbContext.RenameStoredProcedureAsBackup(IpWhatWillBePoliced);
            }

            ReloadPage(driver);
            page.FirstTitleLink.ClickWithTimeout();

            Assert.True(driver.FindElements(affectedCasesMessageSelector).Count == 0);

            page.MaintenanceModal.Title().Clear();
            page.MaintenanceModal.Title().SendKeys("1A a new title" + RandomString.Next(6));
            page.MaintenanceModal.Notes().SendKeys("test");

            UnsavedRunNow(page, common);

            page.MaintenanceModal.Save.ClickWithTimeout();
            Assert.NotNull(common.FlashAlert());

            page.MaintenanceModal.Attributes.CaseReference.EnterAndSelect("test");

            UnsavedRunNow(page, common);

            Assert.True(driver.FindElements(affectedCasesMessageSelector).Count == 0);
            Assert.True(driver.FindElements(affectedCasesSaveRequiredMessageSelector).Count == 0);

            page.MaintenanceModal.Save.ClickWithTimeout();
        }
    }
}