using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaSearch
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CriteriaSearchEvents : IntegrationTest

    {
    [TestCase(BrowserType.Chrome)]
    [TestCase(BrowserType.Ie)]
    [TestCase(BrowserType.FireFox)]
    public void SearchByEvents(BrowserType browserType)
    {
        CriteriaSearchDbSetup.Result dataFixture;
        using (var setup = new CriteriaSearchDbSetup())
        {
            dataFixture = setup.Setup();
        }

        var driver = BrowserProvider.Get(browserType);
        SignIn(driver, "/#/configuration/rules/workflows");
        driver.FindRadio("search-by-event").Click();

        var protectedCriteria = driver.FindElement(By.Id("characteristics-include-protected-criteria"));

        Assert.IsTrue(protectedCriteria.Selected, "Protected criteria is ticked by default if a user has MaintainWorkflowRulesProtected permission");

        var searchResults = new KendoGrid(driver, "searchResults");
        var searchOptions = new SearchOptions(driver);
        var eventPl = new PickList(driver).ByName("ip-search-by-event", "event");

        void SearchForReferencedEvent(string eventDescription, int eventNo)
        {
            driver.WithJs().ScrollToTop();
            eventPl.EnterAndSelect(eventNo.ToString());
            Assert2.WaitEqual(3, 500, () => eventDescription, () => eventPl.GetText());

            searchOptions.SearchButton.ClickWithTimeout();

            Assert.AreEqual(dataFixture.CriteriaNo.ToString(), searchResults.LockedCellText(0, 3));
            Assert.AreEqual(1, searchResults.Rows.Count);
        }

        SearchForReferencedEvent(CriteriaSearchDbSetup.EventDescription, dataFixture.EventId);
        SearchForReferencedEvent(CriteriaSearchDbSetup.UpdateFromEventDescription, dataFixture.ReferencedEvents.UpdateFrom);
        SearchForReferencedEvent(CriteriaSearchDbSetup.DueDateEventDescription, dataFixture.ReferencedEvents.DueDate);
        SearchForReferencedEvent(CriteriaSearchDbSetup.DatesLogicEventDescription, dataFixture.ReferencedEvents.DatesLogic);
        SearchForReferencedEvent(CriteriaSearchDbSetup.RelatedEventsEventDescription, dataFixture.ReferencedEvents.RelatedEvents);
        SearchForReferencedEvent(CriteriaSearchDbSetup.RequiredEventsEventDescription, dataFixture.ReferencedEvents.EventRequired);
        SearchForReferencedEvent(CriteriaSearchDbSetup.DetailDatesEventDescription, dataFixture.ReferencedEvents.DetailDates);
        SearchForReferencedEvent(CriteriaSearchDbSetup.DetailControlEventDescription, dataFixture.ReferencedEvents.DetailControl);
    }
    }
}