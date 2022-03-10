using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EntryControl;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.ValidCombinations;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Status
{
    [Category(Categories.E2E)]
    [TestFixture]
    // These tests can only be run on Inprotech Versions 12.1 onward
    
    public class ValidStatusPicklist : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ValidStatusesFromEventControl(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
                                  {
                                      var country = setup.Insert(new Country("e2e", "e2e-Country", "3"));
                                      var propertyType = setup.Insert(new InprotechKaizen.Model.Cases.PropertyType("2", "e2e-PropertyType"));
                                      var caseType = setup.Insert(new InprotechKaizen.Model.Cases.CaseType("2", "e2e-CaseType"));

                                      var criteria = setup.InsertWithNewId(new Criteria
                                                                           {
                                                                               Description = Fixture.Prefix("e2e"),
                                                                               PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                                               CaseType = caseType,
                                                                               Country = country,
                                                                               PropertyType = propertyType
                                                                           });

                                      var @event = setup.InsertWithNewId(new Event {Description = "e2e event", NumberOfCyclesAllowed = 999, Notes = "e2e Event Notes"});
                                      setup.Insert(new ValidEvent(criteria, @event) {Inherited = 1});

                                      // set up change status
                                      var validCaseStatus = setup.InsertWithNewId(new InprotechKaizen.Model.Cases.Status {Name = "e2e-Valid-CaseStatus", RenewalFlag = 0});
                                      setup.Insert(new ValidStatus(country, propertyType, caseType, validCaseStatus));
                                      var caseStatus = setup.InsertWithNewId(new InprotechKaizen.Model.Cases.Status {Name = Fixture.Prefix("e2e-CaseStatus"), RenewalFlag = 0});

                                      var validRenewalStatus = setup.InsertWithNewId(new InprotechKaizen.Model.Cases.Status {Name = "e2e-Valid-RenewalStatus", RenewalFlag = 1});
                                      setup.Insert(new ValidStatus(country, propertyType, caseType, validRenewalStatus));
                                      var renewalStatus = setup.InsertWithNewId(new InprotechKaizen.Model.Cases.Status {Name = Fixture.Prefix("e2e-RenewalStatus"), RenewalFlag = 1});

                                      return new
                                             {
                                                 EventId = @event.Id,
                                                 CriteriaId = criteria.Id,
                                                 CaseStatus = caseStatus,
                                                 RenewalStatus = renewalStatus,
                                                 ValidCaseStatus = validCaseStatus,
                                                 ValidRenewalStatus = validRenewalStatus
                                             };
                                  });

            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);

            SignIn(driver, "/#/configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId);

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.ChangeStatus.NavigateTo();

            #region Case Status
            eventControlPage.ChangeStatus.CaseStatus.Typeahead.SendKeys(Keys.ArrowDown);
            Assert.AreEqual(1, eventControlPage.ChangeStatus.CaseStatus.TypeAheadList.Count,
                            "Expected only valid Case Statuses to be displayed");
            
            eventControlPage.ChangeStatus.CaseStatus.Typeahead.SendKeys("e2e");
            driver.WaitForAngularWithTimeout(); //somehow requires a delay
            Assert.AreEqual(2, eventControlPage.ChangeStatus.CaseStatus.TypeAheadList.Count,
                            "Expected all matching Case Statuses to be displayed");

            eventControlPage.ChangeStatus.CaseStatus.Clear();
            eventControlPage.ChangeStatus.CaseStatus.OpenPickList();
            var searchResults = new KendoGrid(driver, "picklistResults");
            var filterByCriteria = new Checkbox(driver).ByLabel("workflows.common.validStatusesOnly");
            Assert.AreEqual(1, searchResults.Rows.Count, "Expected only Valid Statuses to be returned without query");
            Assert.IsTrue(filterByCriteria.IsChecked, "Expected Show Only Valid Statuses option to be ticked when searching without query");
            filterByCriteria.Click();
            Assert.AreNotEqual(2, searchResults.Rows.Count, "Expected all statuses to be returned when not filtering");
            searchResults.ClickRow(0);
            popups.ConfirmModal.Cancel().Click();
            Assert.IsFalse(eventControlPage.ChangeStatus.CaseStatus.HasError, "Expected selected Case Status to be valid");
            Assert.IsEmpty(eventControlPage.ChangeStatus.CaseStatus.Typeahead.Value());

            eventControlPage.ChangeStatus.CaseStatus.OpenPickList("e2e");
            filterByCriteria = new Checkbox(driver).ByLabel("workflows.common.validStatusesOnly");
            Assert.IsFalse(filterByCriteria.IsChecked, "Expected Show Only Valid Statuses option to be unticked when searching with query");
            searchResults = new KendoGrid(driver, "picklistResults");
            searchResults.ClickRow(0);
            Assert.IsFalse(eventControlPage.ChangeStatus.CaseStatus.HasError,"Expected selected Case Status to be valid");

            eventControlPage.ChangeStatus.CaseStatus.Clear();
            eventControlPage.ChangeStatus.CaseStatus.EnterAndSelect(data.CaseStatus.Name);
            popups.ConfirmModal.Proceed();
            Assert.IsFalse(eventControlPage.ChangeStatus.CaseStatus.HasError, "Expected selected Case Status to be valid");
            Assert.AreEqual(data.CaseStatus.Name, eventControlPage.ChangeStatus.CaseStatus.GetText());
            #endregion 

            #region Renewal Status
            eventControlPage.ChangeStatus.RenewalStatus.Typeahead.SendKeys(Keys.ArrowDown);
            Assert.AreEqual(1, eventControlPage.ChangeStatus.RenewalStatus.TypeAheadList.Count,
                            "Expected only valid Renewal Statuses to be displayed");

            eventControlPage.ChangeStatus.RenewalStatus.Typeahead.SendKeys("e2e");
            driver.WaitForAngularWithTimeout(); //somehow requires a delay
            Assert.AreEqual(2, eventControlPage.ChangeStatus.RenewalStatus.TypeAheadList.Count,
                            "Expected all matching Renewal Statuses to be displayed");

            eventControlPage.ChangeStatus.RenewalStatus.Clear();
            eventControlPage.ChangeStatus.RenewalStatus.OpenPickList();
            searchResults = new KendoGrid(driver, "picklistResults");
            filterByCriteria = new Checkbox(driver).ByLabel("workflows.common.validStatusesOnly");
            Assert.AreEqual(1, searchResults.Rows.Count, "Expected only Valid Statuses to be returned without query");
            Assert.IsTrue(filterByCriteria.IsChecked, "Expected Show Only Valid Statuses option to be ticked when searching without query");
            filterByCriteria.Click();
            Assert.AreNotEqual(2, searchResults.Rows.Count, "Expected all statuses to be returned when not filtering");
            searchResults.ClickRow(0);
            popups.ConfirmModal.Cancel().Click();
            Assert.IsFalse(eventControlPage.ChangeStatus.RenewalStatus.HasError, "Expect selected Renewal Status to be valid");
            Assert.IsEmpty(eventControlPage.ChangeStatus.RenewalStatus.Typeahead.Value());

            eventControlPage.ChangeStatus.RenewalStatus.OpenPickList("e2e");
            filterByCriteria = new Checkbox(driver).ByLabel("workflows.common.validStatusesOnly");
            Assert.IsFalse(filterByCriteria.IsChecked, "Expected Show Only Valid Statuses option to be unticked when searching with query");
            searchResults = new KendoGrid(driver, "picklistResults");
            searchResults.ClickRow(0);
            Assert.IsFalse(eventControlPage.ChangeStatus.RenewalStatus.HasError,"Expect selected Renewal Status to be valid");

            eventControlPage.ChangeStatus.RenewalStatus.Clear();
            eventControlPage.ChangeStatus.RenewalStatus.EnterAndSelect(data.RenewalStatus.Name);
            popups.ConfirmModal.Proceed();
            Assert.IsFalse(eventControlPage.ChangeStatus.RenewalStatus.HasError, "Expected selected Renewal Status to be valid");
            Assert.AreEqual(data.RenewalStatus.Name, eventControlPage.ChangeStatus.RenewalStatus.GetText());
            #endregion

            //https://github.com/mozilla/geckodriver/issues/1151
            eventControlPage.RevertButton.Click();
            eventControlPage.Discard();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ValidStatusesFromEntryControl(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
                                  {
                                      var country = setup.Insert(new Country("e2e", "e2e-Country", "3"));
                                      var propertyType = setup.Insert(new InprotechKaizen.Model.Cases.PropertyType("2", "e2e-PropertyType"));
                                      var caseType = setup.Insert(new InprotechKaizen.Model.Cases.CaseType("2", "e2e-CaseType"));

                                      var criteria = setup.InsertWithNewId(new Criteria
                                                                           {
                                                                               Description = Fixture.Prefix("e2e"),
                                                                               PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                                               CaseType = caseType,
                                                                               Country = country,
                                                                               PropertyType = propertyType
                                                                           });

                                      var @event = setup.InsertWithNewId(new Event { Description = "e2e event", NumberOfCyclesAllowed = 999, Notes = "e2e Event Notes" });
                                      setup.Insert(new ValidEvent(criteria, @event) { Inherited = 1 });

                                      var entry = setup.Insert(new DataEntryTask
                                                         {
                                                             CriteriaId = criteria.Id,
                                                             ShouldPoliceImmediate = true
                                                         });

                                      // set up change status
                                      var validCaseStatus = setup.InsertWithNewId(new InprotechKaizen.Model.Cases.Status { Name = "e2e-Valid-CaseStatus", RenewalFlag = 0 });
                                      setup.Insert(new ValidStatus(country, propertyType, caseType, validCaseStatus));
                                      var caseStatus = setup.InsertWithNewId(new InprotechKaizen.Model.Cases.Status { Name = Fixture.Prefix("e2e-CaseStatus"), RenewalFlag = 0 });

                                      var validRenewalStatus = setup.InsertWithNewId(new InprotechKaizen.Model.Cases.Status { Name = "e2e-Valid-RenewalStatus", RenewalFlag = 1 });
                                      setup.Insert(new ValidStatus(country, propertyType, caseType, validRenewalStatus));
                                      var renewalStatus = setup.InsertWithNewId(new InprotechKaizen.Model.Cases.Status { Name = Fixture.Prefix("e2e-RenewalStatus"), RenewalFlag = 1 });

                                      return new
                                             {
                                                 EntryId = entry.Id,
                                                 EventId = @event.Id,
                                                 CriteriaId = criteria.Id,
                                                 CaseStatus = caseStatus,
                                                 RenewalStatus = renewalStatus,
                                                 ValidCaseStatus = validCaseStatus,
                                                 ValidRenewalStatus = validRenewalStatus
                                             };
                                  });

            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);

            SignIn(driver, "/#/configuration/rules/workflows/" + data.CriteriaId + "/entrycontrol/" + data.EntryId);

            var entryControlPage = new EntryControlPage(driver);
            entryControlPage.ChangeStatus.NavigateTo();

            #region Case Status
            entryControlPage.ChangeStatus.ChangeCaseStatusPl.Typeahead.SendKeys(Keys.ArrowDown);
            Assert.AreEqual(1, entryControlPage.ChangeStatus.ChangeCaseStatusPl.TypeAheadList.Count,
                            "Expected only valid Case Statuses to be displayed");

            entryControlPage.ChangeStatus.ChangeCaseStatusPl.Typeahead.SendKeys("e2e");
            driver.WaitForAngularWithTimeout(); //somehow requires a delay
            Assert.AreEqual(2, entryControlPage.ChangeStatus.ChangeCaseStatusPl.TypeAheadList.Count,
                            "Expected all matching Case Statuses to be displayed");

            entryControlPage.ChangeStatus.ChangeCaseStatusPl.Clear();
            entryControlPage.ChangeStatus.ChangeCaseStatusPl.OpenPickList();
            var searchResults = new KendoGrid(driver, "picklistResults");
            var filterByCriteria = new Checkbox(driver).ByLabel("workflows.common.validStatusesOnly");
            Assert.AreEqual(1, searchResults.Rows.Count, "Expected only Valid Statuses to be returned without query");
            Assert.IsTrue(filterByCriteria.IsChecked, "Expected Show Only Valid Statuses option to be ticked when searching without query");
            filterByCriteria.Click();
            Assert.AreNotEqual(2, searchResults.Rows.Count, "Expected all statuses to be returned when not filtering");
            searchResults.ClickRow(0);
            popups.ConfirmModal.Cancel().Click();
            Assert.IsFalse(entryControlPage.ChangeStatus.ChangeCaseStatusPl.HasError, "Expected selected Case Status to be valid");
            Assert.IsEmpty(entryControlPage.ChangeStatus.ChangeCaseStatusPl.GetText(), "Expected invalid Case Status to be cleared");

            entryControlPage.ChangeStatus.ChangeCaseStatusPl.OpenPickList("e2e");
            filterByCriteria = new Checkbox(driver).ByLabel("workflows.common.validStatusesOnly");
            Assert.IsFalse(filterByCriteria.IsChecked, "Expected Show Only Valid Statuses option to be unticked when searching with query");
            searchResults = new KendoGrid(driver, "picklistResults");
            searchResults.ClickRow(0);
            Assert.IsFalse(entryControlPage.ChangeStatus.ChangeCaseStatusPl.HasError, "Expected selected Case Status to be valid");

            entryControlPage.ChangeStatus.ChangeCaseStatusPl.Clear();
            entryControlPage.ChangeStatus.ChangeCaseStatusPl.EnterAndSelect(data.CaseStatus.Name);
            popups.ConfirmModal.Proceed();
            Assert.IsFalse(entryControlPage.ChangeStatus.ChangeCaseStatusPl.HasError, "Expected selected Case Status to be valid");
            Assert.AreEqual(data.CaseStatus.Name, entryControlPage.ChangeStatus.ChangeCaseStatusPl.GetText(), "Expected newly added Case Status to be valid");
            #endregion

            #region Renewal Status
            entryControlPage.ChangeStatus.ChangeRenewalStatusPl.Typeahead.SendKeys(Keys.ArrowDown);
            Assert.AreEqual(1, entryControlPage.ChangeStatus.ChangeRenewalStatusPl.TypeAheadList.Count,
                            "Expected only valid Renewal Statuses to be displayed");

            entryControlPage.ChangeStatus.ChangeRenewalStatusPl.Typeahead.SendKeys("e2e");
            driver.WaitForAngularWithTimeout(); //somehow requires a delay
            Assert.AreEqual(2, entryControlPage.ChangeStatus.ChangeRenewalStatusPl.TypeAheadList.Count,
                            "Expected all matching Renewal Statuses to be displayed");

            entryControlPage.ChangeStatus.ChangeRenewalStatusPl.Clear();
            entryControlPage.ChangeStatus.ChangeRenewalStatusPl.OpenPickList();
            searchResults = new KendoGrid(driver, "picklistResults");
            filterByCriteria = new Checkbox(driver).ByLabel("workflows.common.validStatusesOnly");
            Assert.AreEqual(1, searchResults.Rows.Count, "Expected only Valid Statuses to be returned without query");
            Assert.IsTrue(filterByCriteria.IsChecked, "Expected Show Only Valid Statuses option to be ticked when searching without query");
            filterByCriteria.Click();
            Assert.AreNotEqual(2, searchResults.Rows.Count, "Expected all statuses to be returned when not filtering");
            searchResults.ClickRow(0);
            popups.ConfirmModal.Cancel().Click();
            Assert.IsFalse(entryControlPage.ChangeStatus.ChangeRenewalStatusPl.HasError, "Expected selected Renewal Status to be valid");
            Assert.IsEmpty(entryControlPage.ChangeStatus.ChangeRenewalStatusPl.GetText(), "Expected invalid Renewal Status to be cleared");

            entryControlPage.ChangeStatus.ChangeRenewalStatusPl.OpenPickList("e2e");
            filterByCriteria = new Checkbox(driver).ByLabel("workflows.common.validStatusesOnly");
            Assert.IsFalse(filterByCriteria.IsChecked, "Expected Show Only Valid Statuses option to be unticked when searching with query");
            searchResults = new KendoGrid(driver, "picklistResults");
            searchResults.ClickRow(0);
            Assert.IsFalse(entryControlPage.ChangeStatus.ChangeRenewalStatusPl.HasError, "Expect selected Renewal Status to be valid");

            entryControlPage.ChangeStatus.ChangeRenewalStatusPl.Clear();
            entryControlPage.ChangeStatus.ChangeRenewalStatusPl.EnterAndSelect(data.RenewalStatus.Name);
            popups.ConfirmModal.Proceed();
            Assert.IsFalse(entryControlPage.ChangeStatus.ChangeRenewalStatusPl.HasError, "Expected selected Renewal Status to be valid");
            Assert.AreEqual(data.RenewalStatus.Name, entryControlPage.ChangeStatus.ChangeRenewalStatusPl.GetText(), "Expected newly added Renewal Staus to be valid");
            #endregion

            //https://github.com/mozilla/geckodriver/issues/1151
            entryControlPage.RevertButton.Click();
            entryControlPage.Discard();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DefaultJurisdictionStatus(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var act = setup.InsertWithNewId(new InprotechKaizen.Model.Cases.Action { Name = "e2e Action" }).Code;
                var criteria = setup.InsertWithNewId(new Criteria
                {
                    Description = "e2e Status Criteria",
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                    UserDefinedRule = 1,
                    RuleInUse = 1,
                    ActionId = act,
                    CountryId = "VN",
                    PropertyTypeId = "T",
                    CaseTypeId = "A"
                });
                var @event = setup.InsertWithNewId(new Event
                {
                    Description = "e2e Status Event"
                });
                var validEvent = setup.Insert( new ValidEvent(criteria, @event, @event.Description));

                return new {Criteria = criteria, Event = @event, ValidEvent = validEvent};
            });
            
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");
            CriteriaHelper.GoToMaintenancePage(driver, data.Criteria.Id, data.Criteria.Id);

            var page = new CriteriaDetailPage(driver);
            page.EventsTopic.TopicContainer.ClickWithTimeout();
            page.EventsTopic.EventsGrid.Cell(0, 2).FindElement(By.CssSelector("a")).Click();

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.ChangeStatus.NavigateTo();
            eventControlPage.ChangeStatus.CaseStatus.OpenPickList();

            var inlineInfo = new InlineAlert(driver);

            Assert.True(inlineInfo.Displayed);
        }
    }
}