using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "12")]
    public class ChangeStatus : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ChangeRenewalStatusNotSupported(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var @event = setup.InsertWithNewId(new Event());
                var criteria = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("child"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });

                var importance = setup.InsertWithNewId(new Importance());
                setup.Insert(new ValidEvent(criteria, @event, Fixture.Prefix("EventControl"))
                {
                    NumberOfCyclesAllowed = 1,
                    Importance = importance
                });

                // set up change status
                var caseStatus = setup.InsertWithNewId(new Status {Name = Fixture.Prefix("CaseStatus"), RenewalFlag = 0});
                var renewalStatus = setup.InsertWithNewId(new Status {Name = Fixture.Prefix("RenewalStatus"), RenewalFlag = 1});

                return new
                {
                    EventId = @event.Id,
                    CriteriaId = criteria.Id,
                    CaseStatus = caseStatus,
                    RenewalStatus = renewalStatus
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId);

            var eventControlPage = new EventControlPage(driver);
            var commonPopups = new CommonPopups(driver);

            eventControlPage.ChangeStatus.NavigateTo();

            eventControlPage.ChangeStatus.Status.EnterAndSelect(data.CaseStatus.Name);
            eventControlPage.ChangeStatus.Status.EnterAndSelect(data.RenewalStatus.Name);

            eventControlPage.Save();
            
            Assert.True(commonPopups.FlashAlertIsDisplayed() || eventControlPage.IsSaveDisabled(), "Flash alert should've been displayed and save button disabled");
            
            ReloadPage(driver);
            Assert.AreEqual(data.RenewalStatus.Name, eventControlPage.ChangeStatus.Status.InputValue, "Changed Status to Renewal Status");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddNewStatus(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var @event = setup.InsertWithNewId(new Event());
                var criteria = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("child"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });

                var importance = setup.InsertWithNewId(new Importance());
                setup.Insert(new ValidEvent(criteria, @event, Fixture.Prefix("EventControl"))
                {
                    NumberOfCyclesAllowed = 1,
                    Importance = importance
                });

                return new
                {
                    EventId = @event.Id,
                    CriteriaId = criteria.Id
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId);
            var eventControlPage = new EventControlPage(driver);
            eventControlPage.ChangeStatus.NavigateTo();
            eventControlPage.ChangeStatus.Status.OpenPickList();
            var statusAddButton = driver.FindElement(By.Name("plus-circle"));
            statusAddButton.Click();
            eventControlPage.NewStatusModal.InternalDescription.Input.SendKeys("e2e status");
            eventControlPage.NewStatusModal.SaveButton.Click();
            var searchResults = new KendoGrid(driver, "picklistResults");

            Assert.AreEqual("e2e status", searchResults.CellText(0, 0),
                            "Ensure Status is saved.");
        }
    }
}
