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

namespace Inprotech.Tests.Integration.EndToEnd.Policing.Scenarios.Administrator
{
    [TestFixture]
    [Category(Categories.E2E)]
    [TestType(TestTypes.Scenario)]
    public class Analyzing : IntegrationTest
    {
        TestUser _loginUser;

        [SetUp]
        public void CreatePoliceAdminUser()
        {
            _loginUser = new Users()
                .WithPermission(ApplicationTask.PolicingAdministration)
                .WithPermission(ApplicationTask.MaintainPolicingRequest)
                .WithPermission(ApplicationTask.MaintainWorkflowRules)
                .Create();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void LookingUpPolicingErrors(BrowserType browserType)
        {
            using (var setup = new AdministratorDbSetup().WithPolicingServerOff())
            {
                var @case = setup.GetCase("caseInQuestion");
                var item = setup.Insert(new PolicingRequest(@case.Id)
                                        {
                                            OnHold = KnownValues.StringToHoldFlag["in-progress"],
                                            TypeOfRequest = (short) KnownValues.StringToTypeOfRequest["open-action"],
                                            IsSystemGenerated = 1,
                                            Name = "E2E Test " + RandomString.Next(6),
                                            DateEntered = Helpers.UniqueDateTime(),
                                            SequenceNo = 1
                                        });

                setup.CreateErrorFor(item);

                Enumerable.Range(0, 10)
                          .ToList()
                          .ForEach(x => setup.CreateError(Helpers.UniqueDateTime(), setup.GetCase(x.ToString())));
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/policing-dashboard", _loginUser.Username, _loginUser.Password);

            driver.With<DashboardPageObject>((dashboard, popups) =>
                                             {
                                                 //One record in error
                                                 Assert.LessOrEqual(1, dashboard.Summary.RequiresAttention.Value());

                                                 dashboard.Summary.RequiresAttention.Link().WithJs().Click();
                                             });

            driver.With<QueuePageObject>((queue, popups) =>
                                         {
                                             Assert.IsTrue(queue.ErrorGrid.CellText(0, 1).StartsWith("E2E Error"), "Error message is displayed");

                                             queue.BackToDashboardLink().WithJs().Click();
                                         });

            driver.With<DashboardPageObject>((dashboard, popups) => { dashboard.ViewErrorLog().WithJs().Click(); });

            driver.With<ErrorLogPageObject>((errorLog, popups) =>
                                            {
                                                //filter on error message
                                                errorLog.ErrorLogGrid.MessageFilter.Open();
                                                errorLog.ErrorLogGrid.MessageFilter.TextInput.Input("E2E Error");
                                                errorLog.ErrorLogGrid.MessageFilter.Filter();

                                                errorLog.ErrorLogGrid.CaseReferenceFilter.Open();
                                                errorLog.ErrorLogGrid.CaseReferenceFilter.TextInput.Input("caseInQuestion");
                                                errorLog.ErrorLogGrid.CaseReferenceFilter.Filter();

                                                //Criteria is a link
                                                var criteriaLink = errorLog.ErrorLogGrid.Cell(0, 7).FindElements(By.TagName("a")).FirstOrDefault();
                                                Assert.IsNotNull(criteriaLink, "Criteria text is a link");
                                                criteriaLink.WithJs().Click();

                                                var criteriaUrl = $"#/configuration/rules/workflows";
                                                var currentUrl = driver.WithJs().GetUrl();

                                                Assert.IsTrue(currentUrl.Contains(criteriaUrl), "Clicking criteria link should navigate to criteria edit screen");
                                                driver.Navigate().Back();
                                            });

            driver.With<ErrorLogPageObject>((errorLog, popups) =>
                                            {
                                                var originalCount = errorLog.ErrorLogGrid.Rows.Count;
                                                errorLog.ErrorLogGrid.SetFocus();
                                                errorLog.ErrorLogGrid.ActionMenu.OpenOrClose();
                                                errorLog.ErrorLogGrid.ActionMenu.SelectPage();
                                                errorLog.ErrorLogGrid.ActionMenu.DeleteOption().WithJs().Click();
                                                popups.ConfirmDeleteModal.Delete().WithJs().Click();

                                                Assert.NotNull(popups.FlashAlert(), "Flash alter of success is displayed, after delete");

                                                Assert.GreaterOrEqual(originalCount, errorLog.ErrorLogGrid.Rows.Count, "Only in progress items are left in error log");
                                            });
        }
    }
}