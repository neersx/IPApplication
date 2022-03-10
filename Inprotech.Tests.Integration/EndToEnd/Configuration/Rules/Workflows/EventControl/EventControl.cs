using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail;
using Inprotech.Tests.Integration.EndToEnd.Picklists.Events;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "12.1")]
    public class EventControl : IntegrationTest
    {
        protected void GotoEventControlPage(NgWebDriver driver, string criteriaId)
        {
            SignIn(driver, "/#/configuration/rules/workflows");

            driver.FindRadio("search-by-criteria").Click();

            var searchResults = new KendoGrid(driver, "searchResults");
            var searchOptions = new SearchOptions(driver);
            var pl = new PickList(driver).ByName("ip-search-by-criteria", "criteria");
            pl.EnterAndSelect(criteriaId);

            searchOptions.SearchButton.ClickWithTimeout();

            driver.WaitForAngular();

            Assert2.WaitTrue(3, 500, () => searchResults.LockedRows.Count > 0, "Search should return some results");

            searchResults.LockedCell(0, 3).FindElement(By.TagName("a")).ClickWithTimeout();

            var workflowDetailsPage = new CriteriaDetailPage(driver);

            workflowDetailsPage.EventsTopic.EventsGrid.Cell(0, "Event No.").FindElement(By.TagName("a")).ClickWithTimeout();
        }
    }
}