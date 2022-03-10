using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Policing;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.Requestlog
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "16.0")]
    [TestFrom(DbCompatLevel.Release16)]
    [TestType(TestTypes.Regression)]
    public class RequestLog16 : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PolicingRequestLogShouldDeletePolicyLog(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var requestLog = new RequestLogPageObject(driver);
            TestUser loginUser;

            using (var setup = new RequestLogDbSetup())
            {
                setup.Insert(new PolicingLog
                {
                    StartDateTime = Helpers.UniqueDateTime(DateTime.Today.AddMonths(-1)),
                    PolicingName = "Test policy to delete",
                    SpId = 1,
                    SpIdStart = Helpers.UniqueDateTime(DateTime.Today.AddMonths(-2))
                }); //Status In Progress with SpId

                loginUser = setup.Users
                                 .WithPermission(ApplicationTask.ViewPolicingDashboard)
                                 .WithPermission(ApplicationTask.MaintainPolicingRequest)
                                 .WithPermission(ApplicationTask.PolicingAdministration)
                                 .Create();
            }

            SignIn(driver, "/#/policing-request-log", loginUser.Username, loginUser.Password);
            requestLog.RequestGrid.PolicingNameFilter.Open();
            requestLog.RequestGrid.PolicingNameFilter.SelectOption("Test policy to delete");
            requestLog.RequestGrid.PolicingNameFilter.Filter();
            requestLog.RequestGrid.Cell(0, 0).FindElement(By.ClassName("btn-icon")).ClickWithTimeout();
            var popups = new CommonPopups(driver);
            Assert.IsNotNull(popups.ConfirmModal, "confirm modal is present");
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(0, requestLog.RequestGrid.MasterRows.Count, "0 record is returned by search");
            requestLog.RequestGrid.PolicingNameFilter.Clear();
        }
    }
}