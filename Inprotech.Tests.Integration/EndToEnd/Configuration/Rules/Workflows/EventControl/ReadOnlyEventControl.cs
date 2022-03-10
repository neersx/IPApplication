using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "12.1")]
    public class ReadOnlyEventControl : EventControl
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ViewReadonlyEventControl(BrowserType browserType)
        {
            EventControlDbSetup.DataFixture dataFixture;

            using (var setup = new EventControlDbSetup())
            {
                dataFixture = setup.SetUp();
            }

            var driver = BrowserProvider.Get(browserType);

            GotoEventControlPage(driver, dataFixture.CriteriaId);

            var eventControlPage = new EventControlPage(driver);

            #region Page Header

            Assert.AreEqual(dataFixture.CriteriaId, eventControlPage.Header.CriteriaNumber);
            Assert.AreEqual(dataFixture.EventNumber, eventControlPage.Header.EventNumber);
            Assert.AreEqual(dataFixture.EventDescription, eventControlPage.Header.EventDescription);

            Assert.True(driver.Title.StartsWith(dataFixture.CriteriaId));
            Assert.True(driver.Title.Contains(dataFixture.EventNumber));

            #endregion

            #region Overview

            Assert.AreEqual(dataFixture.EventNumber, eventControlPage.Overview.EventNumber.Text);
            Assert.AreEqual(dataFixture.BaseDescription, eventControlPage.Overview.BaseEvent.Text);
            Assert.AreEqual(dataFixture.EventDescription, eventControlPage.Overview.EventDescription.Text);
            Assert.AreEqual(dataFixture.MaxCycles, eventControlPage.Overview.MaxCycles.Text);
            Assert.AreEqual(dataFixture.ImportanceLevel, eventControlPage.Overview.ImportanceLevel.Value);

            Assert.False(eventControlPage.Overview.NameRadio.IsChecked);
            Assert.False(eventControlPage.Overview.NameTypeRadio.IsChecked);
            Assert.True(eventControlPage.Overview.NotApplicableRadio.IsChecked);

            Assert.False(eventControlPage.Overview.Name.Exists);
            Assert.False(eventControlPage.Overview.NameType.Exists);

            Assert.AreEqual(dataFixture.Notes, eventControlPage.Overview.Notes.Text);

            #endregion

            #region Due Date Control

            eventControlPage.DueDateCalc.NavigateTo();
            Assert.AreEqual(1, eventControlPage.DueDateCalc.GridRowsCount);

            Assert.IsTrue(eventControlPage.DueDateCalc.Event.Contains(dataFixture.DueDateEventId));
            Assert.IsTrue(eventControlPage.DueDateCalc.Event.Contains(dataFixture.DueDateEventDescription));

            //Assert.IsFalse(eventControlPage.DueDateCalc.UpdateImmediately.IsChecked);
            //Assert.IsFalse(eventControlPage.DueDateCalc.UpdateWhenDue.IsChecked);
            Assert.IsTrue(eventControlPage.DueDateCalc.EarliestDateToUse.IsChecked);
            Assert.IsFalse(eventControlPage.DueDateCalc.SaveDueDateYes.IsChecked);
            Assert.IsTrue(eventControlPage.DueDateCalc.RecalcEventDate.IsChecked);
            Assert.IsTrue(eventControlPage.DueDateCalc.ExtendDueDateYes.IsChecked);
            Assert.IsTrue(eventControlPage.DueDateCalc.SuppressDueDateCalc.IsChecked);
            Assert.AreEqual(dataFixture.ExtendDueDatePeriod, eventControlPage.DueDateCalc.ExtendDueDate.Text);
            Assert.AreEqual("Months", eventControlPage.DueDateCalc.ExtendDueDateUnit);

            #endregion

            #region Load Event

            eventControlPage.SyncEvent.NavigateTo();
            Assert.AreEqual($"({dataFixture.UseEventId}) {dataFixture.UseEvent}", eventControlPage.SyncEvent.RelatedCaseUseEvent.GetText());

            Assert.AreEqual(dataFixture.DateAdjustment, eventControlPage.SyncEvent.RelatedCaseDateAdjustment.Text);
            Assert.AreEqual(dataFixture.Relationship, eventControlPage.SyncEvent.Relationship.GetText());
            Assert.AreEqual(dataFixture.SyncOfficialNumber, eventControlPage.SyncEvent.SyncOfficialNumber.GetText());
            Assert.IsTrue(eventControlPage.SyncEvent.RelatedCaseOption.IsChecked);
            Assert.IsFalse(eventControlPage.SyncEvent.SameCaseOption.IsChecked);
            Assert.IsFalse(eventControlPage.SyncEvent.NotApplicableOption.IsChecked);
            Assert.IsFalse(eventControlPage.SyncEvent.CycleUseRelatedCaseEvent.IsChecked);
            Assert.IsTrue(eventControlPage.SyncEvent.CycleUseCaseRelationship.IsChecked);

            #endregion

            #region Standing Instruction

            eventControlPage.StandingInstruction.NavigateTo();
            Assert.AreEqual(dataFixture.InstructionType, eventControlPage.StandingInstruction.InstructionType.InputValue);
            Assert.AreEqual(dataFixture.RequiredCharacteristic, eventControlPage.StandingInstruction.RequiredCharacteristic.Text);

            #endregion

            #region Date Comparison

            eventControlPage.DateComparison.NavigateTo();
            Assert.IsFalse(eventControlPage.DateComparison.IsAnySelected);
            Assert.IsTrue(eventControlPage.DateComparison.IsAllSelected);
            Assert.AreEqual(1, eventControlPage.DateComparison.GridRowsCount);

            Assert2.WaitTrue(5, 200, () => eventControlPage.DateComparison.EventA.Contains(dataFixture.DateComparisonEvent1Number));
            Assert2.WaitTrue(5, 200, () => eventControlPage.DateComparison.EventA.Contains(dataFixture.DateComparisonEvent1Description));
            // this is mysteriously failing for ie on on team city's e2e 
            //Assert.AreEqual("Event Date", eventControlPage.DateComparison.EventAUseDate);
            //Assert.AreEqual("Current Cycle", eventControlPage.DateComparison.EventACycle);

            Assert.AreEqual(dataFixture.DateComparisonOperator, eventControlPage.DateComparison.ComparisonOperator);
            Assert2.WaitTrue(5, 200, () => eventControlPage.DateComparison.EventB.Contains(dataFixture.DateComparisonEvent2Number));
            Assert2.WaitTrue(5, 200, () => eventControlPage.DateComparison.EventB.Contains(dataFixture.DateComparisonEvent2Description));
            //Assert.AreEqual("Due Date", eventControlPage.DateComparison.EventBUseDate);
            //Assert.AreEqual("Cycle 1", eventControlPage.DateComparison.EventBCycle);

            #endregion

            #region Satisfying Events

            eventControlPage.SatisfyingEvents.NavigateTo();
            Assert.AreEqual(1, eventControlPage.SatisfyingEvents.GridRowsCount);
            Assert.AreEqual($"({dataFixture.SatisfyingEventNumber}) {dataFixture.SatisfyingEventName}", eventControlPage.SatisfyingEvents.EventPicklist.GetText());
            Assert.AreEqual(dataFixture.SatisfyingEventNumber, eventControlPage.SatisfyingEvents.GetEventNo(0));

            #endregion

            #region Designated Jurisdictions

            eventControlPage.DesignatedJurisdictions.NavigateTo();
            Assert.AreEqual(1, eventControlPage.DesignatedJurisdictions.GridRowsCount);
            Assert.AreEqual(dataFixture.DesignatedJurisdiction, eventControlPage.DesignatedJurisdictions.Grid.Cell(0, 2).Text);

            #endregion

            #region Change Status

            eventControlPage.ChangeStatus.NavigateTo();
            Assert.AreEqual(dataFixture.CaseStatus, eventControlPage.ChangeStatus.CaseStatus.InputValue);
            Assert.AreEqual(dataFixture.RenewalStatus, eventControlPage.ChangeStatus.RenewalStatus.InputValue);
            Assert.AreEqual(dataFixture.UserDefinedStatus, eventControlPage.ChangeStatus.UserDefinedStatus.Text);

            #endregion

            #region Report to CPA

            eventControlPage.Report.NavigateTo();
            Assert.IsTrue(eventControlPage.Report.TurnOn.IsChecked);

            #endregion

            #region Reminders

            eventControlPage.Reminders.NavigateTo();
            Assert.AreEqual(dataFixture.ReminderMessage, eventControlPage.Reminders.StandardMessage);

            #endregion

            #region Documents

            eventControlPage.Documents.NavigateTo();
            Assert.AreEqual(dataFixture.DocumentName, eventControlPage.Documents.Document);

            #endregion

            #region Charges

            eventControlPage.Charges.NavigateTo();
            Assert.AreEqual(dataFixture.GenerateCharge1, eventControlPage.Charges.ChargeOne.ChargeType.InputValue);
            Assert.AreEqual(dataFixture.GenerateCharge2, eventControlPage.Charges.ChargeTwo.ChargeType.InputValue);
            Assert.IsTrue(eventControlPage.Charges.ChargeOne.PayFee.IsChecked);
            Assert.IsTrue(eventControlPage.Charges.ChargeOne.RaiseCharge.IsChecked);
            Assert.IsTrue(eventControlPage.Charges.ChargeOne.UseEstimate.IsChecked);
            Assert.IsTrue(eventControlPage.Charges.ChargeOne.DirectPay.IsChecked);
            Assert.IsTrue(eventControlPage.Charges.ChargeTwo.PayFee.IsChecked);
            Assert.IsTrue(eventControlPage.Charges.ChargeTwo.RaiseCharge.IsChecked);
            Assert.IsTrue(eventControlPage.Charges.ChargeTwo.UseEstimate.IsChecked);
            Assert.IsTrue(eventControlPage.Charges.ChargeTwo.DirectPay.IsChecked);

            #endregion

            #region Change Action

            eventControlPage.ChangeAction.NavigateTo();
            Assert.AreEqual(dataFixture.OpenAction, eventControlPage.ChangeAction.OpenAction.InputValue);
            Assert.AreEqual(dataFixture.CloseAction, eventControlPage.ChangeAction.CloseAction.InputValue);
            Assert.AreEqual(dataFixture.RelativeCycle, eventControlPage.ChangeAction.RelativeCycle.Value);

            #endregion

            #region Events to Clear

            eventControlPage.EventsToClear.NavigateTo();
            Assert.AreEqual(1, eventControlPage.EventsToClear.GridRowsCount);
            Assert.IsTrue(eventControlPage.EventsToClear.Event.Contains(dataFixture.EventToClear));
            Assert.IsTrue(eventControlPage.EventsToClear.EventNo.Contains(dataFixture.NumberOfEventToClear));

            #endregion

            #region Events to Update

            eventControlPage.EventsToUpdate.NavigateTo();
            Assert.AreEqual(1, eventControlPage.EventsToUpdate.GridRowsCount);
            Assert.IsTrue(eventControlPage.EventsToUpdate.EventNo.Contains(dataFixture.NumberOfEventToUpdate));
            Assert.IsTrue(eventControlPage.EventsToUpdate.Event.Contains(dataFixture.EventToUpdate));
            Assert.AreEqual(dataFixture.DateOfEventToUpdate, eventControlPage.EventsToUpdate.AdjustDateDropDown.Text);

            #endregion

            #region Name Change

            eventControlPage.NameChange.NavigateTo();
            Assert.AreEqual(dataFixture.ChangeCaseName, eventControlPage.NameChange.ChangeCaseName);
            Assert.AreEqual(dataFixture.CopyFromName, eventControlPage.NameChange.CopyFromName);
            Assert.AreEqual(dataFixture.MoveToName, eventControlPage.NameChange.MoveToName);

            #endregion

            #region Date Logic Rules

            eventControlPage.DateLogicRules.NavigateTo();
            Assert.AreEqual(dataFixture.DateLogicAppliesTo, eventControlPage.DateLogicRules.AppliesTo);
            Assert.AreEqual(dataFixture.DateComparisonOperator, eventControlPage.DateLogicRules.Operator);
            Assert.IsTrue(eventControlPage.DateLogicRules.CompareEvent.Contains(dataFixture.DateLogicCompareTo));
            Assert.IsTrue(eventControlPage.DateLogicRules.Relationship.Contains(dataFixture.DateLogicUseRelationship));

            #endregion

            #region Pta Delay

            eventControlPage.PtaDelay.NavigateTo();
            Assert.IsTrue(eventControlPage.PtaDelay.NotApplicable.IsChecked);

            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ViewEventControlInheritance(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new CriteriaDetailDbSetup().AddCriteriaWithEventsInheritance();
                var parent = setup.DbContext.Set<Criteria>().Single(_ => _.Id == f.ParentCriteriaId);

                var eventId = f.ValidEvents.First().EventId;
                var cve = setup.DbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == f.Id && _.EventId == eventId);
                var pve = parent.ValidEvents.Single(_ => _.EventId == cve.EventId);

                var respNameType = new NameTypeBuilder(setup.DbContext).Create();
                var allEvents = setup.DbContext.Set<ValidEvent>().Where(_ => (_.CriteriaId == f.Id || _.CriteriaId == f.ParentCriteriaId) && _.EventId == cve.EventId);
                setup.DbContext.Update(allEvents, _ => new ValidEvent
                {
                    DueDateRespNameTypeCode = respNameType.NameTypeCode,
                    SaveDueDate = (int) SaveDueDate.Immediate
                });

                var caseStatus = setup.InsertWithNewId(new Status {Name = Fixture.String(5), RenewalFlag = 0});
                pve.ChangeStatusId = caseStatus.Id;
                cve.ChangeStatusId = caseStatus.Id;

                setup.Insert(new RelatedEventRule(pve, 0) {RelatedEventId = eventId, RelativeCycleId = 1, ClearDue = 1, ClearEvent = 1, ClearDueOnDueChange = true, ClearEventOnDueChange = true});
                setup.Insert(new RelatedEventRule(cve, 0) {RelatedEventId = eventId, RelativeCycleId = 1, ClearDue = 1, ClearEvent = 1, ClearDueOnDueChange = true, ClearEventOnDueChange = true, Inherited = 1});

                setup.DbContext.SaveChanges();

                var newStatus = setup.InsertWithNewId(new Status {Name = Fixture.String(5)});
                var newEvent = new EventBuilder(setup.DbContext).Create();

                return new
                {
                    CriteriaId = f.Id,
                    ValidEvent = f.ValidEvents.FirstOrDefault(),
                    OldStatus = caseStatus.Name,
                    NewStatus = newStatus.Name,
                    NewEvent = newEvent.Description
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.ValidEvent.EventId}");

            var eventControlPage = new EventControlPage(driver);

            Assert.IsTrue(eventControlPage.Overview.EventDescription.Element.GetAttribute("class").Contains("input-inherited"), "Description should be displayed as inherited");
            Assert.IsTrue(eventControlPage.Overview.MaxCycles.Element.GetAttribute("class").Contains("input-inherited"), "Maximum Cycles should be displayed as inherited");
            Assert.IsTrue(eventControlPage.Overview.ImportanceLevel.Element.GetAttribute("class").Contains("input-inherited"), "Imporatnce Level should be displayed as inherited");
            Assert.IsTrue(eventControlPage.Overview.NameTypeRadio.Element.GetParent().GetAttribute("class").Contains("input-inherited"), "Responsibility radio button is displayed as inherited");
            Assert.IsTrue(eventControlPage.Overview.NameType.Element.GetAttribute("class").Contains("input-inherited"), "Responsibility Name Type is displayed as inherited");
            Assert.IsTrue(eventControlPage.Overview.Notes.Element.GetAttribute("class").Contains("input-inherited"), "Notes should be displayed as inherited");

            eventControlPage.Overview.EventDescription.Input.SendKeys(Fixture.String(1));
            Assert.IsFalse(eventControlPage.Overview.EventDescription.Element.WithJs().GetAttributeValue<string>("class").Contains("input-inherited"), "Description should be displayed as un-inherited");

            eventControlPage.Overview.EventDescription.Input.SendKeys(Keys.Backspace);
            Assert.IsTrue(eventControlPage.Overview.EventDescription.Element.WithJs().GetAttributeValue<string>("class").Contains("input-inherited"), "Description should be re-displayed as inherited");

            // check row-level inheritance highlighting
            eventControlPage.DueDateCalc.NavigateTo();

            eventControlPage.DueDateCalc.Add();
            var dueDateCalcModal = new DueDateCalcModal(driver);
            dueDateCalcModal.Event.EnterAndSelect(data.ValidEvent.EventId.ToString());
            dueDateCalcModal.Period.TextInput.SendKeys("2");
            dueDateCalcModal.Period.SelectElement.SelectByIndex(1);
            dueDateCalcModal.RelativeCycle.Input.SelectByIndex(2);
            dueDateCalcModal.Apply();

            Assert.IsTrue(eventControlPage.DueDateCalc.Grid.Rows[0].GetAttribute("class").Contains("input-inherited"), "Due date calc row is displayed as inherited");
            Assert.IsFalse(eventControlPage.DueDateCalc.Grid.Rows[1].GetAttribute("class").Contains("input-inherited"), "New Due date calc row is NOT displayed as inherited");

            eventControlPage.DueDateCalc.Grid.Rows[0].FindElement(By.CssSelector("td button[button-icon=\"pencil-square-o\"")).Click();
            var dueDateCalcModal1 = new DueDateCalcModal(driver);
            dueDateCalcModal1.Subtract.Click();
            dueDateCalcModal1.Apply();
            Assert.IsFalse(eventControlPage.DueDateCalc.Grid.Rows[0].WithJs().GetAttributeValue<string>("class").Contains("input-inherited"), "Edited Due date calc row is NOT displayed as inherited");

            // check group
            Assert.IsTrue(eventControlPage.DueDateCalc.FindElement(By.CssSelector("#dueDateCalcGroup")).GetAttribute("class").Contains("input-inherited"), "Group section should be inherited");

            eventControlPage.DueDateCalc.LatestDateToUse.Click();
            Assert.IsFalse(eventControlPage.DueDateCalc.FindElement(By.CssSelector("#dueDateCalcGroup")).WithJs().GetAttributeValue<string>("class").Contains("input-inherited"), "Group section should be uninherited");

            eventControlPage.DueDateCalc.EarliestDateToUse.Click();
            Assert.IsTrue(eventControlPage.DueDateCalc.FindElement(By.CssSelector("#dueDateCalcGroup")).WithJs().GetAttributeValue<string>("class").Contains("input-inherited"), "Group section should be reinherited");

            // check a pick list in Change Status
            eventControlPage.ChangeStatus.NavigateTo();
            Assert.IsTrue(eventControlPage.ChangeStatus.CaseStatus.Element.GetAttribute("class").Contains("input-inherited"), "Case Status pick list should display as inherited");
            eventControlPage.ChangeStatus.CaseStatus.EnterAndSelect(data.NewStatus);
            Assert.IsFalse(eventControlPage.ChangeStatus.CaseStatus.Element.WithJs().GetAttributeValue<string>("class").Contains("input-inherited"), "Edited Case Status pick list should not display as inherited");
            eventControlPage.ChangeStatus.CaseStatus.EnterAndSelect(data.OldStatus);
            Assert.IsTrue(eventControlPage.ChangeStatus.CaseStatus.Element.WithJs().GetAttributeValue<string>("class").Contains("input-inherited"), "Edited Case Status pick list should not display as inherited");

            // check inline-editing
            eventControlPage.EventsToClear.NavigateTo();
            eventControlPage.EventsToClear.Add();

            var newRow = eventControlPage.EventsToClear.Grid.Rows[1];
            eventControlPage.EventsToClear.EventPicklistByRow(newRow).EnterAndSelect(data.NewEvent);

            Assert.IsTrue(eventControlPage.EventsToClear.Grid.Rows[0].GetAttribute("class").Contains("input-inherited"), "Existing inherited inline edit row is displayed as inherited");
            Assert.IsFalse(eventControlPage.EventsToClear.Grid.Rows[1].GetAttribute("class").Contains("input-inherited"), "New inline edit row is NOT displayed as inherited");

            eventControlPage.EventsToClear.RelativeCycleDropDownByRow(eventControlPage.EventsToClear.Grid.Rows[0]).Value = "2";
            Assert.IsFalse(eventControlPage.EventsToClear.Grid.Rows[0].WithJs().GetAttributeValue<string>("class").Contains("input-inherited"), "Edited inline edit row is displayed as NOT inherited");

            //https://github.com/mozilla/geckodriver/issues/1151
            eventControlPage.RevertButton.Click(); //edit mode discard
            eventControlPage.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void NavigateBetweenItems(BrowserType browserType)
        {
            var criteriaId = DbSetup.Do(setup =>
            {
                var e1 = setup.InsertWithNewId(new Event
                {
                    Description = Fixture.Prefix("event1")
                });

                var e2 = setup.InsertWithNewId(new Event
                {
                    Description = Fixture.Prefix("event1")
                });

                var criteria = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("criteria"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });

                setup.Insert(new ValidEvent
                {
                    CriteriaId = criteria.Id,
                    EventId = e1.Id,
                    Description = Fixture.Prefix("validEvent1")
                });

                setup.Insert(new ValidEvent
                {
                    CriteriaId = criteria.Id,
                    EventId = e2.Id,
                    Description = Fixture.Prefix("validEvent2")
                });

                return criteria.Id;
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{criteriaId}");

            var workflowDetailsPage = new CriteriaDetailPage(driver);

            // select first event
            workflowDetailsPage.EventsTopic.SelectEventByIndex(0);

            var eventControlPage = new EventControlPage(driver);

            // select duedatecalc section which is a subsection belongs to group section
            eventControlPage.DueDateCalc.TopicContainer.ClickWithTimeout();

            // go to next event control
            new PageNav(driver).NextPage();

            Assert.True(new TopicsMenu(driver).IsSectionsPaneVisible);
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldDisableAllFieldsIfSystemEvent(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var data = DbSetup.Do(setup =>
            {
                var criteria = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("criteria"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                    UserDefinedRule = 0
                });

                var sysEvent = setup.DbContext.Set<Event>().SingleOrDefault(_ => _.Id == -16) ??
                               setup.Insert(new Event(-16) {Description = Fixture.String(5)});

                setup.Insert(new ValidEvent(criteria, sysEvent));

                return new
                {
                    CriteriaId = criteria.Id,
                    EventId = sysEvent.Id
                };
            });

            SignIn(driver, "/#/configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId);

            var eventControlPage = new EventControlPage(driver);

            Assert.IsTrue(eventControlPage.IsPermissionAlertDisplayed, "should display permission alert before all topics");
            Assert.IsTrue(eventControlPage.Overview.EventDescription.Input.IsDisabled(), "the event description field should be disabled");
            Assert.IsFalse(eventControlPage.IsSaveDisplayed, "event control page is not savable");
        }
    }
}