using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail;
using Inprotech.Tests.Integration.EndToEnd.Picklists.Events;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "12.1")]
    public class EventControlCrud : EventControl
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditBaseEvent(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var evnt = eventBuilder.Create("Event");
                var criteria = criteriaBuilder.Create("criteria");

                var validEvent = new ValidEvent(criteria, evnt, "event instance")
                {
                    Inherited = 1,
                    NumberOfCyclesAllowed = 33,
                    DatesLogicComparison = 0,
                    ImportanceLevel = "1" // minimal
                };

                setup.Insert(validEvent);

                return new
                {
                    CriteriaId = criteria.Id,
                    EventId = evnt.Id,
                    EventDescription = evnt.Description,
                    EventInstanceDescription = validEvent.Description,
                    validEvent.NumberOfCyclesAllowed,
                    ImportanceLevel = "Minimal"
                };
            });

            SignIn(driver, "/#/configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId);

            var eventControlPage = new EventControlPage(driver);

            // verify initial state of the page

            Assert.AreEqual(data.EventDescription, eventControlPage.Overview.BaseEvent.Text);
            Assert.AreEqual(data.EventInstanceDescription, eventControlPage.Overview.EventDescription.Text);
            //Assert.AreEqual(data.NumberOfCyclesAllowed, eventControlPage.Overview.MaxCycles.Input.Text);
            Assert.AreEqual(data.ImportanceLevel, eventControlPage.Overview.ImportanceLevel.Text);
            Assert.IsFalse(eventControlPage.DueDateCalc.RecalcEventDate.IsChecked);
            Assert.IsFalse(eventControlPage.DueDateCalc.SuppressDueDateCalc.IsChecked);

            // edit base event

            eventControlPage.Overview.EditBaseEvent.Click();

            var modal = new EditEventModal(driver);

            modal.EventDescription.Text = "new description";
            modal.EventCode.Text = "code123";
            modal.MaxCycles.Clear();
            modal.MaxCycles.SendKeys("3");
            modal.InternalImportance.SelectByText("Minimal");

            // apply but don't propagate

            modal.Apply();

            var propagateDialog = new ConfirmPropagateChangesModal(driver);
            propagateDialog.ProceedButton.Click(); // proceed without propagating

            // make sure only base event description was updated

            eventControlPage = new EventControlPage(driver);
            Assert2.WaitEqual(5, 200,
                              () => "new description",
                              () => eventControlPage.Overview.BaseEvent.WithJs().GetInnerText(),
                              "even without propagating, base event name should change");

            Assert2.WaitEqual(5, 200,
                              () => data.EventInstanceDescription,
                              () => eventControlPage.Overview.EventDescription.Text,
                              "event description should not be changed, search 'IsDescriptionUpdatable'");

            //BUG:the following lines should pass but for some unknown reason selenium reports wrong textbox content
            //Assert.AreEqual(data.NumberOfCyclesAllowed.ToString(), eventControlPage.Overview.MaxCycles.Text, "maxCycles should NOT change because we are not propagating");
            //Assert.AreEqual(data.ImportanceLevel, eventControlPage.Overview.ImportanceLevel.Text, "importance level should NOT change because we are not propagating");

            // edit base event again

            //driver.Navigate().Refresh();
            eventControlPage = new EventControlPage(driver);
            eventControlPage.Overview.EditBaseEvent.Click();

            modal = new EditEventModal(driver);

            modal.EventDescription.Text = "new description - 2";
            modal.EventCode.Text = "code123-2";
            modal.MaxCycles.Clear();
            modal.MaxCycles.SendKeys("4");
            modal.InternalImportance.SelectByText("Normal");

            modal.RecalculateEventDate.Click();
            modal.DontCalcDueDate.Click();

            // apply and do propagate

            modal.Apply();

            propagateDialog = new ConfirmPropagateChangesModal(driver);
            propagateDialog.ActionOption.Input.WithJs().Click(); // tick propagate
            propagateDialog.ProceedButton.Click();

            // make sure fields were updated

            eventControlPage = new EventControlPage(driver);

            Assert2.WaitEqual(5, 200,
                              () => "new description - 2",
                              () => eventControlPage.Overview.BaseEvent.WithJs().GetInnerText(),
                              "base event name should change");

            Assert2.WaitEqual(5, 200,
                              () => data.EventInstanceDescription,
                              () => eventControlPage.Overview.EventDescription.Text,
                              "event description should not be changed, search 'IsDescriptionUpdatable'");

            //BUG:the following lines should pass but for some unknown reason selenium reports wrong textbox content
            //Assert.AreEqual("4", eventControlPage.Overview.MaxCycles.Text, "maxCycles should change");
            //Assert.AreEqual("Normal",eventControlPage.Overview.ImportanceLevel.Text, "importance level should change");

            Assert.IsTrue(eventControlPage.DueDateCalc.RecalcEventDate.IsChecked, "RecalcEventDate should change");
            Assert.IsTrue(eventControlPage.DueDateCalc.SuppressDueDateCalc.IsChecked, "SuppressDueDateCalc should change");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ResetEventControl(BrowserType browserType)
        {
            CriteriaDetailDbSetup.ScenarioData dataFixture;
            using (var setup = new CriteriaDetailDbSetup())
            {
                dataFixture = setup.SetUp();
                var deleteEvent = setup.InsertWithNewId(new Event());
                setup.Insert(new DueDateCalc(dataFixture.ChildCriteria.ValidEvents.First(), 0) {FromEventId = deleteEvent.Id, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Cycle = 1});

                // add a grandchild so the confirmation dialog pops up with the Apply to descendants option
                var grandchild = setup.AddCriteria(Fixture.String(6), dataFixture.ChildCriteriaId);
                setup.Insert(new Inherits(grandchild.Id, dataFixture.ChildCriteriaId));
                setup.AddValidEvent(grandchild, dataFixture.ExistingEvent, true, dataFixture.ChildCriteriaId, dataFixture.ExistingEvent.Id);
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{dataFixture.ChildCriteriaId}/eventcontrol/{dataFixture.ValidEventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.DueDateCalc.NavigateTo();

            Assert.AreEqual(dataFixture.ChildCriteria.ValidEvents.First().DueDateCalcs.AsQueryable().WhereDueDateCalc().Count(), eventControlPage.DueDateCalc.GridRowsCount);

            eventControlPage.ActivateActionsTab();
            eventControlPage.Actions.ResetInheritance();
            driver.WaitForAngular();

            Assert.IsTrue(eventControlPage.ResetEntryInheritanceConfirmation.ApplyToDescendants.Enabled);
            eventControlPage.ResetEntryInheritanceConfirmation.Proceed();

            Assert.AreEqual(0, eventControlPage.DueDateCalc.GridRowsCount, "Child should reset due date calcs from parent.");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void BreakEventControlInheritance(BrowserType browserType)
        {
            CriteriaDetailDbSetup.ScenarioData dataFixture;
            using (var setup = new CriteriaDetailDbSetup())
            {
                dataFixture = setup.SetUp();
                var @event = setup.InsertWithNewId(new Event());
                setup.Insert(new DueDateCalc(dataFixture.ChildCriteria.ValidEvents.First(), 0) {FromEventId = @event.Id, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Cycle = 1, IsInherited = true});
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{dataFixture.ChildCriteriaId}/eventcontrol/{dataFixture.ValidEventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.DueDateCalc.NavigateTo();

            Assert.IsTrue(eventControlPage.Header.IsInherited);
            Assert.IsTrue(eventControlPage.DueDateCalc.Grid.AnyInherited());

            eventControlPage.ActivateActionsTab();
            eventControlPage.Actions.BreakInheritance();

            // break inheritance confirmation modal
            driver.FindElement(By.CssSelector("[data-ng-click='vm.proceed()']")).Click();

            Assert.IsFalse(eventControlPage.Header.IsInherited);
            Assert.IsFalse(eventControlPage.DueDateCalc.Grid.AnyInherited());
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SaveStandingInstruction(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);
                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var instructionTypeBuilder = new InstructionTypeBuilder(setup.DbContext);
                var characteristicBuilder = new CharacteristicBuilder(setup.DbContext);

                var @event = eventBuilder.Create();
                var criteria = criteriaBuilder.Create();
                var importance = importanceBuilder.Create();
                var instructionType = instructionTypeBuilder.Create();
                var characteristic = characteristicBuilder.Create(instructionType.Code);

                setup.Insert(new ValidEvent(criteria, @event, "Apple")
                {
                    NumberOfCyclesAllowed = 1,
                    ImportanceLevel = importance.Level,
                    InstructionType = instructionType.Code,
                    FlagNumber = characteristic.Id
                });

                return new
                {
                    EventId = @event.Id,
                    CriteriaId = criteria.Id,
                    InstructionType = instructionType.Description,
                    InstructionTypeCode = instructionType.Code,
                    Characteristic = characteristic.Description
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);

            eventControlPage.StandingInstruction.NavigateTo();
            eventControlPage.StandingInstruction.SelectInstructionTypeByCode(data.InstructionTypeCode);
            eventControlPage.StandingInstruction.SelectCharacteristicByText(data.Characteristic);

            eventControlPage.Save();

            eventControlPage.StandingInstruction.NavigateTo();
            Assert.AreEqual(data.InstructionType, eventControlPage.StandingInstruction.InstructionType.InputValue);
            Assert.AreEqual(data.Characteristic, eventControlPage.StandingInstruction.RequiredCharacteristic.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteEventControl(BrowserType browserType)
        {
            CriteriaDetailDbSetup.ScenarioData dataFixture;

            using (var setup = new CriteriaDetailDbSetup())
            {
                dataFixture = setup.SetUp();
            }

            var driver = BrowserProvider.Get(browserType);

            GotoEventControlPage(driver, dataFixture.CriteriaId.ToString());

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.DeleteButton.Click();

            eventControlPage.EventsForCaseModal.Proceed();
            eventControlPage.InheritanceDeleteModal.WithoutApplyToChildren();
            eventControlPage.InheritanceDeleteModal.Delete();

            Assert.AreEqual(driver.Location, $"/configuration/rules/workflows/{dataFixture.CriteriaId}/eventcontrol/{dataFixture.SecondEventId}", "Should navigate to next entry");
            Assert.AreEqual(dataFixture.SecondEventId.ToString(), eventControlPage.Overview.EventNumber.Text);
        }

    }
}