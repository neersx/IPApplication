using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Policing;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.Requestlog
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestType(TestTypes.Regression)]
    public class RequestLog : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PolicingRequestLogFilters(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            PolicingLog log1, log2;

            using (var setup = new RequestLogDbSetup())
            {
                log1 = setup.Insert(new PolicingLog
                                    {
                                        StartDateTime = Helpers.UniqueDateTime(DateTime.Today.AddDays(-1)),
                                        FinishDateTime = Helpers.UniqueDateTime(),
                                        PolicingName = "Test 1"
                                    }); //Status complete

                log2 = setup.Insert(new PolicingLog
                                    {
                                        StartDateTime = Helpers.UniqueDateTime(DateTime.Today.AddDays(-1)),
                                        FinishDateTime = Helpers.UniqueDateTime(),
                                        PolicingName = "Test 2" + RandomString.Next(6)
                                    }); //Status complete

                setup.Insert(new PolicingLog
                             {
                                 StartDateTime = Helpers.UniqueDateTime(DateTime.Today.AddMonths(-1)),
                                 PolicingName = "Test 3"
                             }); //Status In Progress

                setup.Insert(new PolicingLog
                             {
                                 StartDateTime = Helpers.UniqueDateTime(DateTime.Today.AddMonths(-1)),
                                 PolicingName = "Test 4" + RandomString.Next(6)
                             }); //Status In Progress

                setup.CreateError(Helpers.UniqueDateTime()); //Status In Error
                setup.CreateError(Helpers.UniqueDateTime()); //Status In Error
            }

            // Log in and navigate to request log page
            SignIn(driver, "/#/policing-request-log");

            driver.With<RequestLogPageObject>((requestLog, popups) =>
                                              {
                                                  Assert.LessOrEqual(6, requestLog.RequestGrid.MasterRows.Count, "There should be atleast 6 rows");

                                                  Assert.NotNull(requestLog.ErrorIconCell, "Error icon should be displayed since by the data setup above, the error row should be the first row.");

                                                  requestLog.RequestGrid.PolicingNameFilter.Open();
                                                  Assert.LessOrEqual(6, requestLog.RequestGrid.PolicingNameFilter.ItemCount, "Policing Name filter should have 6 items by default");
                                                  requestLog.RequestGrid.PolicingNameFilter.Dismiss();

                                                  requestLog.RequestGrid.StatusFilter.Open();
                                                  Assert.LessOrEqual(3, requestLog.RequestGrid.StatusFilter.ItemCount, "Status filter should have atleast 3 items by default");
                                                  requestLog.RequestGrid.StatusFilter.SelectOption("Completed");

                                                  requestLog.RequestGrid.StatusFilter.Filter();
                                                  Assert.LessOrEqual(2, requestLog.RequestGrid.MasterRows.Count, "There should be 2 rows filtered by Status == 'Completed'");
                                                  Assert.Null(requestLog.ErrorIconCell, "Error icon not displayed since no error");

                                                  requestLog.RequestGrid.PolicingNameFilter.Open();
                                                  Assert.LessOrEqual(2, requestLog.RequestGrid.PolicingNameFilter.ItemCount, "Policing Name filter should have 2 items");
                                                  requestLog.RequestGrid.PolicingNameFilter.SelectOption("Test 1");
                                                  requestLog.RequestGrid.PolicingNameFilter.Filter();
                                                  Assert.AreEqual(1, requestLog.RequestGrid.MasterRows.Count, "There should be 1 row filtered by Status == 'Completed' and PolicingName == 'E2E Test Data RequestLog Log test 1'");

                                                  requestLog.RequestGrid.StatusFilter.Open();
                                                  Assert.LessOrEqual(1, requestLog.RequestGrid.StatusFilter.ItemCount, "Status filter should have 1 items");
                                                  requestLog.RequestGrid.StatusFilter.Dismiss();

                                                  requestLog.RequestGrid.PolicingNameFilter.Open();
                                                  requestLog.RequestGrid.PolicingNameFilter.Clear();
                                                  requestLog.RequestGrid.StatusFilter.Open();
                                                  requestLog.RequestGrid.StatusFilter.Clear();
                                                  Assert.LessOrEqual(6, requestLog.RequestGrid.MasterRows.Count, "There should be 6 rows");

                                                  // Policing on or after ...
                                                  requestLog.RequestGrid.DateStartedFilter.Open();
                                                  requestLog.RequestGrid.DateStartedFilter.SetDateIsBefore(DateTime.Today.AddMonths(-1).AddDays(1), true);
                                                  requestLog.RequestGrid.DateStartedFilter.Filter();
                                                  Assert.LessOrEqual(2, requestLog.RequestGrid.MasterRows.Count, "There should be 2 rows filtered by Date > 1 Month");

                                                  // Policing on or after and other filter
                                                  requestLog.RequestGrid.PolicingNameFilter.Open();
                                                  requestLog.RequestGrid.PolicingNameFilter.SelectOption("Test 3");
                                                  requestLog.RequestGrid.PolicingNameFilter.Filter();
                                                  Assert.LessOrEqual(1, requestLog.RequestGrid.MasterRows.Count, "There should be 1 row filtered by Date > 1 Month and Policing name equals 3");

                                                  requestLog.RequestGrid.PolicingNameFilter.Open();
                                                  requestLog.RequestGrid.PolicingNameFilter.Clear();
                                                  requestLog.RequestGrid.DateStartedFilter.Open();
                                                  requestLog.RequestGrid.DateStartedFilter.Clear();

                                                  Assert.LessOrEqual(6, requestLog.RequestGrid.MasterRows.Count, "There should be 6 rows");

                                                  // Policing finish on ...
                                                  requestLog.RequestGrid.DateCompletedFilter.Open();
                                                  requestLog.RequestGrid.DateCompletedFilter.Operator.SelectByText("Is Equal");
                                                  requestLog.RequestGrid.DateCompletedFilter.DatePicker.Enter(DateTime.Today.ToString("yyyy-MM-dd"));
                                                  requestLog.RequestGrid.DateCompletedFilter.Filter();

                                                  Assert.LessOrEqual(2, requestLog.RequestGrid.MasterRows.Count, "There should be 2 rows filtered by Date equals today, which includes all part of the same day.");

                                                  requestLog.RequestGrid.DateCompletedFilter.Open();
                                                  requestLog.RequestGrid.DateCompletedFilter.Clear();

                                                  // Policing before ...
                                                  requestLog.RequestGrid.DateStartedFilter.Open();
                                                  requestLog.RequestGrid.DateStartedFilter.Operator.SelectByText("Is Before");
                                                  requestLog.RequestGrid.DateStartedFilter.DatePicker.Enter(DateTime.Today.AddMonths(-2).ToString("yyyy-MM-dd"));
                                                  requestLog.RequestGrid.DateStartedFilter.Filter();

                                                  Assert.LessOrEqual(0, requestLog.RequestGrid.MasterRows.Count, "There should be no row before two months");

                                                  requestLog.RequestGrid.DateStartedFilter.Open();
                                                  requestLog.RequestGrid.DateStartedFilter.Clear();

                                                  // Delete a couple of items
                                                  using (var setup = new RequestLogDbSetup())
                                                  {
                                                      setup.DeleteLog(log1);
                                                      setup.DeleteLog(log2);
                                                  }

                                                  requestLog.RequestGrid.PolicingNameFilter.Open();
                                                  Assert.LessOrEqual(4, requestLog.RequestGrid.PolicingNameFilter.ItemCount, "Policing Name filter should have 4 items");
                                                  requestLog.RequestGrid.PolicingNameFilter.Dismiss();

                                                  requestLog.RequestGrid.StatusFilter.Open();
                                                  Assert.LessOrEqual(2, requestLog.RequestGrid.StatusFilter.ItemCount, "Status filter should have 2 items");
                                                  requestLog.RequestGrid.StatusFilter.Dismiss();
                                              });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PolicingRequestLogShouldHyperlinkToSavedRequestPage(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var requestLog = new RequestLogPageObject(driver);
            TestUser loginUser;

            using (var setup = new RequestLogDbSetup())
            {
                var request = setup.Insert(new PolicingRequest(null)
                {
                    DateEntered = Helpers.UniqueDateTime(DateTime.Today.AddDays(1)),
                    Name = "Request" + RandomString.Next(6)
                });
                setup.Insert(new PolicingLog
                {
                    StartDateTime = Helpers.UniqueDateTime(DateTime.Today.AddDays(1)),
                    FinishDateTime = Helpers.UniqueDateTime(),
                    PolicingName = request.Name
                });

                loginUser = setup.Users
                                 .WithPermission(ApplicationTask.ViewPolicingDashboard)
                                 .WithPermission(ApplicationTask.MaintainPolicingRequest)
                                 .Create();
            }

            SignIn(driver, "/#/policing-request-log", loginUser.Username, loginUser.Password);

            requestLog.RequestGrid.Cell(0, 1).FindElement(By.TagName("a")).ClickWithTimeout();

            Assert.IsTrue(driver.Url.Contains("policing-saved-requests"), "clicking saved request link should navigate to saved request area");
        }
    }
}