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

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.ErrorLog
{
    [TestFixture]
    [Category(Categories.E2E)]
    [TestType(TestTypes.Regression)]
    public class ErrorLog : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PolicingErrorLogFilters(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var threeDaysLater = Helpers.UniqueDateTime(DateTime.Today.AddDays(3));
            var twoDaysLater = Helpers.UniqueDateTime(DateTime.Today.AddDays(2));

            TestUser loginUser;
            var case2 = Fixture.Prefix("2");
            var case3 = Fixture.Prefix("3");
            var prefix = Fixture.Prefix();
            string failMessage;
            using (var setup = new ErrorLogDbSetup().WithPolicingServerOff())
            {
                setup.CreateError(threeDaysLater);
                setup.CreateError(Helpers.UniqueDateTime(twoDaysLater), setup.GetCase(case2));
                failMessage = setup.CreateError(Helpers.UniqueDateTime(twoDaysLater), setup.GetCase(case3)).Message;
                loginUser = setup.Users
                                 .WithPermission(ApplicationTask.ViewPolicingDashboard)
                                 .Create();
            }

            SignIn(driver, "/#/policing-error-log", loginUser.Username, loginUser.Password);

            driver.With<ErrorLogPageObject>((errorLog, popups) =>
                                            {
                                                Assert.GreaterOrEqual(errorLog.ErrorLogGrid.Rows.Count, 3, "There should be more than 3 rows");

                                                errorLog.ErrorLogGrid.ErrorDateFilter.Open();
                                                errorLog.ErrorLogGrid.ErrorDateFilter.SetDateIsOnOrAfter(DateTime.Today.AddDays(1));
                                                errorLog.ErrorLogGrid.ErrorDateFilter.Filter();

                                                Assert.AreEqual(3, errorLog.ErrorLogGrid.Rows.Count, "There should be 2 rows filtered request from next two days");

                                                errorLog.ErrorLogGrid.ErrorDateFilter.Open();
                                                errorLog.ErrorLogGrid.ErrorDateFilter.Clear();

                                                Assert.LessOrEqual(3, errorLog.ErrorLogGrid.Rows.Count, "There should be more than 3 rows");

                                                errorLog.ErrorLogGrid.CaseReferenceFilter.Open();
                                                errorLog.ErrorLogGrid.CaseReferenceFilter.SelectTextContains(prefix);
                                                errorLog.ErrorLogGrid.CaseReferenceFilter.Filter();

                                                Assert.AreEqual(2, errorLog.ErrorLogGrid.Rows.Count, "There should be 2 rows");

                                                errorLog.ErrorLogGrid.MessageFilter.Open();
                                                errorLog.ErrorLogGrid.MessageFilter.SelectTextEquals(failMessage);
                                                errorLog.ErrorLogGrid.MessageFilter.Filter();

                                                Assert.AreEqual(1, errorLog.ErrorLogGrid.Rows.Count, "There should be more than 1 rows");
                                            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PolicingErrorLogEventAndCriteriaFilters(BrowserType browserType)
        {
            TestUser loginUser;
            string caseRefUrl;
            using (var setup = new ErrorLogDbSetup().WithPolicingServerOff())
            {
                var @case = setup.GetCase("test-ref1");
                var item = setup.Insert(new PolicingRequest(@case.Id)
                {
                    OnHold = KnownValues.StringToHoldFlag["in-error"],
                    TypeOfRequest = (short)KnownValues.StringToTypeOfRequest["open-action"],
                    IsSystemGenerated = 1,
                    Name = "E2E Test " + RandomString.Next(6),
                    DateEntered = Helpers.UniqueDateTime(),
                    SequenceNo = 1
                });

                setup.CreateErrorFor(item);
                loginUser = setup.Users
                                   .WithPermission(ApplicationTask.ViewPolicingDashboard)
                                   .Create();
            }

            var driver = BrowserProvider.Get(browserType);
            var currentNumberOfErrors = 1;
            var requiringAttention = 0;
            string currentUrl;

            SignIn(driver, "/#/policing-error-log", loginUser.Username, loginUser.Password);

            driver.With<ErrorLogPageObject>((errorLog, popups) =>
            {
                Assert.GreaterOrEqual(errorLog.ErrorLogGrid.Rows.Count, 3, "There should be more than 3 rows");

                errorLog.ErrorLogGrid.EventFilter.Open();
                errorLog.ErrorLogGrid.EventFilter.SelectStartsWith("e2e-event");
                errorLog.ErrorLogGrid.EventFilter.Filter();

                Assert.AreEqual(1, errorLog.ErrorLogGrid.Rows.Count, "There should be more than 1 rows");

                errorLog.ErrorLogGrid.EventFilter.Open();
                errorLog.ErrorLogGrid.EventFilter.Clear();

                Assert.GreaterOrEqual(errorLog.ErrorLogGrid.Rows.Count, 3, "There should be more than 3 rows");

                errorLog.ErrorLogGrid.CriteriaFilter.Open();
                errorLog.ErrorLogGrid.CriteriaFilter.SelectTextContains("e2e");
                errorLog.ErrorLogGrid.CriteriaFilter.Filter();

                Assert.AreEqual(1, errorLog.ErrorLogGrid.Rows.Count, "There should be more than 1 rows");
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeletePolicingLogDeletableErrors(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var fiveDaysAfter = Helpers.UniqueDateTime(DateTime.Today.AddDays(5));
            var foureDaysAfter = Helpers.UniqueDateTime(DateTime.Today.AddDays(4));

            TestUser loginUser;
            string caseIrn;
            using (var setup = new ErrorLogDbSetup().WithPolicingServerOff())
            {
                var colleages = setup.OtherUsers.Create();
                var request1 = setup.EnqueueFor(colleages.Mary, "in-error", "open-action", setup.GetCase(Fixture.Prefix("4")), foureDaysAfter);
                setup.CreateErrorFor(request1);
                setup.CompleteRequest(request1);
                setup.Delete(request1);

                var request2 = setup.EnqueueFor(colleages.Mary, "in-error", "open-action", setup.GetCase(Fixture.Prefix("4")), fiveDaysAfter);
                setup.CreateErrorFor(request2);
                setup.CompleteRequest(request2);
                setup.Delete(request2);

                var @case = setup.GetCase(Fixture.Prefix("1"));
                var today1 = Helpers.UniqueDateTime(DateTime.Today);
                var request3 = setup.EnqueueFor(colleages.Mary, "in-progress", "open-action", @case, today1);
                setup.CreateErrorFor(request3);

                var today2 = Helpers.UniqueDateTime(DateTime.Today);
                var request4 = setup.EnqueueFor(colleages.Mary, "in-progress", "open-action", @case, today2);
                setup.CreateErrorFor(request4);
                caseIrn = @case.Irn;

                loginUser = setup.Users
                                 .WithPermission(ApplicationTask.PolicingAdministration)
                                 .Create();
            }

            SignIn(driver, "/#/policing-error-log", loginUser.Username, loginUser.Password);

            driver.With<ErrorLogPageObject>((errorLog, popups) =>
                                            {
                                                Assert.LessOrEqual(3, errorLog.ErrorLogGrid.Rows.Count, "There should be at least 3 rows");
                                                Assert.LessOrEqual(2, errorLog.InProgressIconCount, "Errors belonging to in progress items are at least 2");

                                                errorLog.ErrorLogGrid.SelectIpCheckbox(0);
                                                errorLog.ErrorLogGrid.SelectIpCheckbox(1);
                                                errorLog.ErrorLogGrid.ActionMenu.OpenOrClose();

                                                errorLog.ErrorLogGrid.ActionMenu.DeleteOption().ClickWithTimeout();
                                                driver.WaitForAngularWithTimeout();

                                                popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

                                                Assert.AreNotEqual(caseIrn, errorLog.ErrorLogGrid.Cell(0, 2).Text, "Error log does not contain error for case e2e-test-ref2 ");
                                            });
        }

        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void LookingUpPolicingErrors(BrowserType browserType)
        {
            PolicingRequest item;
            PolicingError firstError;
            TestUser loginUser;
            string caseRefUrl;
            using (var setup = new ErrorLogDbSetup().WithPolicingServerOff())
            {
                var @case = setup.GetCase("test-ref1");
                caseRefUrl = Helpers.GetCaseRefLink(@case.Irn);
                item = setup.Insert(new PolicingRequest(@case.Id)
                {
                    OnHold = KnownValues.StringToHoldFlag["in-error"],
                    TypeOfRequest = (short)KnownValues.StringToTypeOfRequest["open-action"],
                    IsSystemGenerated = 1,
                    Name = "E2E Test " + RandomString.Next(6),
                    DateEntered = Helpers.UniqueDateTime(),
                    SequenceNo = 1
                });

                firstError = setup.CreateErrorFor(item);

                loginUser = setup.Users
                                 .WithPermission(ApplicationTask.PolicingAdministration)
                                 .WithPermission(ApplicationTask.MaintainWorkflowRules)
                                 .Create();
            }

            var driver = BrowserProvider.Get(browserType);
            var currentNumberOfErrors = 1;
            var requiringAttention = 0;
            string currentUrl;

            SignIn(driver, "/#/policing-dashboard", loginUser.Username, loginUser.Password);
            driver.With<DashboardPageObject>((dashboard, popups) => { dashboard.ViewErrorLog().WithJs().Click(); });

            driver.With<ErrorLogPageObject>((errorLog, popups) =>
                                            {
                                                //Check case refernce link
                                                var currentCaseRefLink = errorLog.ErrorLogGrid.Cell(0, 3).FindElements(By.TagName("a")).FirstOrDefault();
                                                Assert.IsNotNull(currentCaseRefLink);
                                                currentCaseRefLink.TestIeOnlyUrl(caseRefUrl);
                                            });

            driver.With<ErrorLogPageObject>((errorLog, popup) =>
                                            {
                                                // Visit error log then drill down to event control

                                                currentUrl = driver.WithJs().GetUrl();

                                                Assert.That(currentUrl.Contains("#/policing-error-log"), "clicking the link should navigate to error log screen");

                                                var eventLink = errorLog.ErrorLogGrid.Cell(0, 5).FindElement(By.TagName("a"));

                                                Assert.That(eventLink.Text.Contains(firstError.EventNo.ToString()), "link text should include event number");

                                                eventLink.WithJs().Click();

                                                var eventControlUrl = $"#/configuration/rules/workflows/{firstError.CriteriaNo}/eventcontrol/{firstError.EventNo}";

                                                currentUrl = driver.WithJs().GetUrl();

                                                Assert.That(currentUrl.Contains(eventControlUrl), "clicking event link should navigate to event control detail screen");

                                                driver.Navigate().Back();
                                            });

            driver.With<ErrorLogPageObject>((errorLog, popups) =>
                                            {
                                                // Error contains criteria link that goes to workflow criteria page.

                                                currentUrl = driver.WithJs().GetUrl();

                                                var criteriaNumberLink = errorLog.ErrorLogGrid.Cell(0, 7).FindElement(By.TagName("a"));

                                                Assert.IsTrue(criteriaNumberLink.Text.Contains(firstError.CriteriaNo.ToString()), "link text should include criteria number");

                                                criteriaNumberLink.WithJs().Click();

                                                driver.WaitForAngularWithTimeout();

                                                var criteriaUrl = $"#/configuration/rules/workflows/{item.CriteriaNo}";

                                                currentUrl = driver.WithJs().GetUrl();

                                                Assert.IsTrue(currentUrl.Contains(criteriaUrl), "clicking criteria link should navigate to criteria edit screen");
                                            });

            driver.Visit("/#/policing-queue/requires-attention");

            driver.With<QueuePageObject>((queue, popup) =>
                                         {
                                             // Visit queue then drill down to workflow criteria

                                             Assert.AreEqual(currentNumberOfErrors, queue.ErrorGrid.Rows.Count, "only the first 1 rows are displayed in the expanded section as there is only single error item");

                                             Assert.Null(queue.ViewAllErrorsLink(), "Popup link is only available if there are more than 5 items");

                                             requiringAttention = queue.Summary.RequiresAttention.Value();

                                             queue.BackToDashboardLink().WithJs().Click();
                                         });

            using (var setup = new ErrorLogDbSetup())
            {
                // add 9 more errors to the same policing log
                Enumerable.Repeat(item, 9).ToList().ForEach(x =>
                                                            {
                                                                setup.CreateErrorFor(x);
                                                                currentNumberOfErrors++;
                                                            });
            }

            driver.With<DashboardPageObject>((dashboard, popup) =>
                                             {
                                                 var newRequiringAttention = dashboard.Summary.RequiresAttention.Value();

                                                 Assert.AreEqual(requiringAttention, newRequiringAttention, "Increasing number of error counts to a policing item should not increment the count");

                                                 dashboard.Summary.RequiresAttention.Link().WithJs().Click();
                                             });

            ReloadPage(driver);
            driver.With<QueuePageObject>((queue, popup) =>
                                         {
                                             Assert.AreEqual(5, queue.ErrorGrid.Rows.Count, "only the first 5 rows are displayed in the expanded section");

                                             Assert.IsTrue(queue.ViewAllErrorsLink().Text.Contains(currentNumberOfErrors.ToString()));

                                             queue.ViewAllErrorsLink().Click();

                                             Assert.AreEqual(currentNumberOfErrors, queue.ErrorDetailGrid.Rows.Count, "all rows are displayed in the popup.");
                                         });
        }
    }
}