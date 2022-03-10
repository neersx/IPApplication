using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class DueDateValidation : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DueDateStandingInstructionWarning(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
                                  {
                                      var eventBuilder = new EventBuilder(setup.DbContext);
                                      var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                                      var criteriaBuilder = new CriteriaBuilder(setup.DbContext);
                                      var instructionTypeBuilder = new InstructionTypeBuilder(setup.DbContext);
                                      var characteristicBuilder = new CharacteristicBuilder(setup.DbContext);

                                      var evnt = eventBuilder.Create("event");
                                      var criteria = criteriaBuilder.Create("criteria");
                                      var importance = importanceBuilder.Create();
                                      var instructionType = instructionTypeBuilder.Create();
                                      var characteristic = characteristicBuilder.Create(instructionType.Code);

                                      var validEvent = new ValidEvent(criteria, evnt, "Apple")
                                                       {
                                                           NumberOfCyclesAllowed = 2,
                                                           Inherited = 1,
                                                           Importance = importance
                                                       };
                                      setup.Insert(validEvent);

                                      return new
                                             {
                                                 Event = evnt.Description,
                                                 EventId = evnt.Id.ToString(),
                                                 CriteriaId = criteria.Id.ToString(),
                                                 InstructionTypeCode = instructionType.Code,
                                                 Characteristic = characteristic.Description
                                             };
                                  });

            var driver = BrowserProvider.Get(browserType);

            // open the event control page and make sure DueDate Calc grid is empty

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");
            var page = new EventControlPage(driver);
            Assert.AreEqual(0, page.DueDateCalc.Grid.Rows.Count, "initally the grid should be empty");
            
            // add new DueDate, should involve warning

            page.DueDateCalc.Add();

            var modal = new DueDateCalcModal(driver);

            modal.Event.EnterAndSelect(data.EventId);

            modal.Period.Text = "2";
            modal.Period.OptionText = "Days";

            Assert.IsFalse(modal.AdjustBy.HasWarning, "initially AdjustBy should have no warning");

            modal.AdjustBy.Input.SelectByText("From Standing Instruction");

            Assert2.WaitTrue(5, 300, () => modal.AdjustBy.HasWarning, "AdjustBy should now have warning");

            modal.Apply();

            Assert.AreEqual(1, page.DueDateCalc.Grid.Rows.Count, "even with warnings, apply should proceed to adding DueDate to the list");

            Assert.IsTrue(page.StandingInstruction.InstructionType.HasError, "now that StandingInstruction-denendent DueDate is there, Standing Instruction section should show error");

            // select a RequiredCharacterisitc - warning should disappear

            page.StandingInstruction.NavigateTo();
            page.StandingInstruction.SelectInstructionTypeByCode(data.InstructionTypeCode);
            page.StandingInstruction.SelectCharacteristicByText(data.Characteristic);

            Assert.IsFalse(page.StandingInstruction.RequiredCharacteristic.HasError, "when populated, StandingInstruction should hide its error");
            
            //lets open DueDate which previously caused warning - it should no more

            page.DueDateCalc.NavigateTo();
            page.DueDateCalc.TopicContainer.WithJs().ScrollIntoView();
            page.DueDateCalc.Grid.ClickEdit(0);

            modal = new DueDateCalcModal(driver);

            Assert.IsFalse(modal.AdjustBy.HasWarning, "warning that was previously there should disappear");

            //https://github.com/mozilla/geckodriver/issues/1151
            page.Discard(); // discard edit due date calculation
            page.Discard(); // confirm the discard
            page.RevertButton.Click();  //edit mode discard
            page.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DueDateMaxCyclesWarning(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
                                  {
                                      var eventBuilder = new EventBuilder(setup.DbContext);
                                      var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                                      var criteriaBuilder = new CriteriaBuilder(setup.DbContext);
                                      var instructionTypeBuilder = new InstructionTypeBuilder(setup.DbContext);
                                      var characteristicBuilder = new CharacteristicBuilder(setup.DbContext);

                                      var evnt = eventBuilder.Create("event");
                                      var criteria = criteriaBuilder.Create("criteria");
                                      var importance = importanceBuilder.Create();
                                      var instructionType = instructionTypeBuilder.Create();
                                      var characteristic = characteristicBuilder.Create(instructionType.Code);

                                      var validEvent = new ValidEvent(criteria, evnt, "Apple")
                                                       {
                                                           NumberOfCyclesAllowed = 2,
                                                           Inherited = 1,
                                                           Importance = importance
                                                       };

                                      setup.Insert(validEvent);

                                      return new
                                             {
                                                 Event = evnt.Description,
                                                 EventId = evnt.Id.ToString(),
                                                 CriteriaId = criteria.Id.ToString(),
                                                 InstructionTypeCode = instructionType.Code,
                                                 Characteristic = characteristic.Description
                                             };
                                  });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");
            var page = new EventControlPage(driver);
            Assert.AreEqual(0, page.DueDateCalc.Grid.Rows.Count, "initally the grid should be empty");

            page.Overview.MaxCycles.Text = "3";

            page.DueDateCalc.Add();

            var modal = new DueDateCalcModal(driver);

            modal.Event.EnterAndSelect(data.EventId);

            modal.Period.OptionText = "Period to be entered";
            modal.ToCycle.Text = "4"; // more than MaxCycles

            Assert2.WaitTrue(5, 300, () => modal.ToCycle.HasWarning, "ToCycle should warn");

            modal.Apply();

            Assert.AreEqual(1, page.DueDateCalc.Grid.Rows.Count, "even with warnings, apply should proceed to adding DueDate to the list");
            Assert.IsTrue(page.Overview.MaxCycles.HasError, "now that faulty DueDate is there, MaxCycles should show error");

            page.Overview.MaxCycles.Text = "4";
            Assert.IsFalse(page.Overview.MaxCycles.HasError, "once corrected, MaxCycles should clear the error");
            
            page.DueDateCalc.NavigateTo();
            page.DueDateCalc.Grid.ClickEdit(0);

            modal = new DueDateCalcModal(driver);

            Assert.IsFalse(modal.ToCycle.HasWarning, "warning that was previously there should disappear");

            //https://github.com/mozilla/geckodriver/issues/1151
            page.Discard(); // discard edit due date calculation
            page.Discard(); // confirm the discard
            page.RevertButton.Click();  //edit mode discard
            page.Discard(); // discard confirm.
        }
    }
}