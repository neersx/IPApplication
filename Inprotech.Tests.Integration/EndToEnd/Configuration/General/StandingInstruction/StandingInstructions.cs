using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.StandingInstructions;
using NUnit.Framework;
using MainPage = Inprotech.Tests.Integration.EndToEnd.Configuration.General.StandingInstruction.StandingInstructionsPage;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.StandingInstruction
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class StandingInstructions : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void QuickCharacteristicAssignment(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var user = new Users()
                .WithPermission(ApplicationTask.MaintainBaseInstructions)
                .Create();

            var data = SetupScenarioData();

            SignIn(driver, "/#/configuration/general/standinginstructions", user.Username, user.Password);

            driver.With<MainPage>(page =>
                                  {
                                      // Initial Load

                                      Assert.True(page.InstructionType.Displayed, "Should display Instruction Type picklist");

                                      Assert.True(page.InstructionType.Enabled, "Should initially enable Instruction Type picklist");

                                      Assert.IsEmpty(page.Instructions.EditableRows, "Should not have any editable rows");

                                      Assert.True(page.Instructions.InformationText.Element.Displayed, "Should display information text in instructions grid");

                                      Assert.True(page.Instructions.AddButton.IsDisabled(), "Should initially disable the add instructions button as no instruction type is selected.");

                                      Assert.IsEmpty(page.Characteristics.DisplayedRows, "Should not have any displayed characteristics");

                                      Assert.True(page.Characteristics.InformationText.Element.Displayed, "Should display information text in characteristics grid");

                                      Assert.True(page.Characteristics.AddButton.IsDisabled(), "Should initially disable the add characteristics button as no instruction type is selected.");
                                  });

            driver.With<MainPage>(page =>
                                  {
                                      page.InstructionType.SendKeys(data.Type1.Code).Blur();

                                      // instruction type with instructions and characteristics selected.

                                      Assert.IsNotEmpty(page.Instructions.EditableRows, "Should have any editable rows");

                                      Assert.False(page.Instructions.AddButton.IsDisabled(), "Should enable the add instructions button as no instruction type is selected.");

                                      Assert.IsEmpty(page.Instructions.SelectedRows, "Should not have any instructions selected (there can only be one item selected at any one time, or none)");

                                      Assert.IsNotEmpty(page.Characteristics.DisplayedRows, "Should have characteristics");

                                      Assert.False(page.Characteristics.AddButton.IsDisabled(), "Should enable the add characteristics button as no instruction type is selected.");

                                      Assert.True(page.Characteristics.Togglers.First().WithJs().IsDisabled(), "Should not be allowed to assign characteristics without any Instructions selected.");

                                      Assert.True(page.Characteristics.Togglers.Last().WithJs().IsDisabled(), "Should not be allowed to assign characteristics without any Instructions selected.");
                                  });

            driver.With<MainPage>(page =>
                                  {
                                      page.Instructions.SelectInstruction(0);

                                      // instruction is selected, so the characteristics now shows 'selected characteristics' 

                                      Assert.IsNotEmpty(page.Instructions.SelectedRows, "Should mark instruction as selected");

                                      Assert.False(page.Characteristics.Togglers.First().WithJs().IsDisabled(), "Should allow toggling of characteristics.");

                                      Assert.False(page.Characteristics.Togglers.Last().WithJs().IsDisabled(), "Should allow toggling of characteristics.");
                                  });

            driver.With<MainPage>(page =>
                                  {
                                      page.Characteristics.Togglers.Last().WithJs().Click();

                                      // toggles now both characteristics should be 'assigned'. 

                                      page.Save();

                                      Assert.AreEqual(1, page.Characteristics.NumberOfRowsInState("saved"), "Should make the row appeared saved");
                                  });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainInstructionsAndCharacteristics(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var user = new Users()
                .WithPermission(ApplicationTask.MaintainBaseInstructions)
                .Create();

            var data = SetupScenarioData();

            SignIn(driver, "/#/configuration/general/standinginstructions", user.Username, user.Password);

            const int rowIndex = 0;

            var instructionType = (string) data.Type1.Code;
            var newInstruction = 'Z' + Fixture.UriSafeString(20);
            var updatedInstruction = 'Z' + Fixture.UriSafeString(20);

            var newCharacteristic = 'Z' + Fixture.UriSafeString(20);
            var updatedCharacteristic = 'Z' + Fixture.UriSafeString(20);

            driver.With<MainPage>(page =>
                                  {
                                      // Add Instruction, save

                                      page.InstructionType.SendKeys(instructionType).Blur();

                                      page.Instructions.AddButton.Click();

                                      page.Instructions.EditableRows.Last().SendKeys(newInstruction);

                                      Assert.True(page.Instructions.EditableRows.Last().WithJs().HasClass("edited"), "Should mark newly added item as 'edited'");

                                      page.Save();

                                      DbSetup.Do(x =>
                                                 {
                                                     var newInstructionInserted = x.DbContext
                                                                                   .Set<Instruction>()
                                                                                   .Any(_ => _.Description == newInstruction && _.InstructionTypeCode == instructionType);

                                                     Assert.True(newInstructionInserted, $"Should insert new instruction '{newInstruction}' against the instruction type '{instructionType}'.");
                                                 });
                                  });

            driver.With<MainPage>(page =>
                                  {
                                      // Instruction validations, save

                                      page.Instructions.EnterText(rowIndex, newInstruction);

                                      Assert.AreEqual(1, page.Instructions.NumberOfRowsInState("error"), "Should highlight the instruction as violating uniqueness constraint");

                                      page.Instructions.EnterText(rowIndex, updatedInstruction);

                                      Assert.AreEqual(0, page.Instructions.NumberOfRowsInState("error"), "Should remove highlight resulted from instruction violating unique contraints");

                                      page.Instructions.EnterText(rowIndex, Fixture.UriSafeString(51));

                                      Assert.AreEqual(1, page.Instructions.NumberOfRowsInState("error"), "Should highlight the instruction as violating max length constraint");

                                      page.Instructions.EnterText(rowIndex, updatedInstruction);

                                      Assert.AreEqual(0, page.Instructions.NumberOfRowsInState("error"), "Should remove highlight resulted from instruction violating max length contraints");

                                      page.Instructions.EnterText(rowIndex, string.Empty);

                                      Assert.AreEqual(1, page.Instructions.NumberOfRowsInState("error"), "Should highlight the instruction as violating mandatory constraint");

                                      page.Instructions.EnterText(rowIndex, updatedInstruction);

                                      Assert.AreEqual(0, page.Instructions.NumberOfRowsInState("error"), "Should remove highlight resulted from instruction violating mandatory contraints");

                                      page.Save();

                                      DbSetup.Do(x =>
                                                 {
                                                     var instructionUpdated = x.DbContext
                                                                               .Set<Instruction>()
                                                                               .Any(_ => _.Description == updatedInstruction && _.InstructionTypeCode == instructionType);

                                                     Assert.True(instructionUpdated, $"Should have an updated instruction '{updatedInstruction}' against the instruction type '{instructionType}'.");
                                                 });
                                  });

            driver.With<MainPage>(page =>
                                  {
                                      // Add Characteristic, save

                                      page.Characteristics.AddButton.Click();

                                      var newCharacteristicRowPosition = page.Characteristics.DisplayedRows.Count - 1;

                                      page.Characteristics.EnterText(newCharacteristicRowPosition, newCharacteristic);

                                      Assert.True(page.Characteristics.DisplayedRows.Last().WithJs().HasClass("edited"), "Should mark newly added item as 'edited'");

                                      page.Save();

                                      DbSetup.Do(x =>
                                                 {
                                                     var newCharacteristicInserted = x.DbContext
                                                                                      .Set<Characteristic>()
                                                                                      .Any(_ => _.Description == newCharacteristic && _.InstructionTypeCode == instructionType);

                                                     Assert.True(newCharacteristicInserted, $"Should insert new characteristic '{newCharacteristic}' against the instruction type '{instructionType}'.");
                                                 });
                                  });

            driver.With<MainPage>(page =>
                                  {
                                      // Characteristic validations, save

                                      page.Characteristics.EnterText(rowIndex, newCharacteristic);

                                      Assert.AreEqual(1, page.Characteristics.NumberOfRowsInState("error"), "Should highlight the characteristic as violating uniqueness constraint");

                                      page.Characteristics.EnterText(rowIndex, updatedCharacteristic);

                                      Assert.AreEqual(0, page.Characteristics.NumberOfRowsInState("error"), "Should remove highlight resulted from characteristic violating unique contraints");

                                      page.Characteristics.EnterText(rowIndex, Fixture.UriSafeString(51));

                                      Assert.AreEqual(1, page.Characteristics.NumberOfRowsInState("error"), "Should highlight the characteristic as violating max length constraint");

                                      page.Characteristics.EnterText(rowIndex, updatedCharacteristic);

                                      Assert.AreEqual(0, page.Characteristics.NumberOfRowsInState("error"), "Should remove highlight resulted from characteristic violating max length contraints");

                                      page.Characteristics.EnterText(rowIndex, string.Empty);

                                      Assert.AreEqual(1, page.Characteristics.NumberOfRowsInState("error"), "Should highlight the characteristic as violating mandatory constraint");

                                      page.Characteristics.EnterText(rowIndex, updatedCharacteristic);

                                      Assert.AreEqual(0, page.Characteristics.NumberOfRowsInState("error"), "Should remove highlight resulted from characteristic violating mandatory contraints");

                                      page.Save();

                                      DbSetup.Do(x =>
                                                 {
                                                     var characteristicUpdated = x.DbContext
                                                                                  .Set<Characteristic>()
                                                                                  .Any(_ => _.Description == newCharacteristic && _.InstructionTypeCode == instructionType);

                                                     Assert.True(characteristicUpdated, $"Should insert new characteristic '{newCharacteristic}' against the instruction type '{instructionType}'.");
                                                 });
                                  });

            driver.With<MainPage>((page, popup) =>
                                  {
                                      // Mark instruction for delete, confirm the save

                                      page.Instructions.DeleteInstruction(1);

                                      popup.ConfirmModal.Yes().WithJs().Click();

                                      Assert.AreEqual(1, page.Instructions.NumberOfRowsInState("deleted"), "Should mark instruction as 'deleted'");

                                      page.Save();

                                      DbSetup.Do(x =>
                                                 {
                                                     var numberOfInstructionRemaining = x.DbContext
                                                                                         .Set<Instruction>()
                                                                                         .Count(_ => _.InstructionTypeCode == instructionType);

                                                     Assert.AreEqual(2, numberOfInstructionRemaining, $"Should have two instructions left against the instruction type '{instructionType}'.");
                                                 });
                                  });

            driver.With<MainPage>((page, popup) =>
                                  {
                                      // Mark characteristic for delete, confirm the save 

                                      page.Characteristics.DeleteCharacteristic(1);

                                      popup.ConfirmModal.Yes().WithJs().Click();

                                      Assert.AreEqual(1, page.Characteristics.NumberOfRowsInState("deleted"), "Should mark characteristic as 'deleted'");

                                      page.Save();

                                      DbSetup.Do(x =>
                                                 {
                                                     var numberOfCharacteristicRemaining = x.DbContext
                                                                                            .Set<Characteristic>()
                                                                                            .Count(_ => _.InstructionTypeCode == instructionType);

                                                     Assert.AreEqual(2, numberOfCharacteristicRemaining, $"Should have two characteristics left against the instruction type '{instructionType}'.");
                                                 });
                                  });
        }

        static dynamic SetupScenarioData()
        {
            return DbSetup.Do(x =>
                              {
                                  var itb = new InstructionTypeBuilder(x.DbContext);

                                  var instructionType1 = itb.Create();
                                  var instructionType2 = itb.Create();
                                  var instructionType3 = itb.Create();

                                  var instruction1 = x.InsertWithNewId(new Instruction
                                                                       {
                                                                           InstructionTypeCode = instructionType1.Code,
                                                                           Description = 'A' + Fixture.UriSafeString(20)
                                                                       }, i => i.Id);

                                  var instruction2 = x.InsertWithNewId(new Instruction
                                                                       {
                                                                           InstructionTypeCode = instructionType1.Code,
                                                                           Description = 'B' + Fixture.UriSafeString(20)
                                                                       }, i => i.Id);

                                  var characteristics1 = x.Insert(new Characteristic
                                                                  {
                                                                      InstructionTypeCode = instructionType1.Code,
                                                                      Id = instruction1.Id,
                                                                      Description = 'A' + Fixture.UriSafeString(20)
                                                                  });

                                  var characteristics2 = x.Insert(new Characteristic
                                                                  {
                                                                      InstructionTypeCode = instructionType1.Code,
                                                                      Id = instruction2.Id,
                                                                      Description = 'B' + Fixture.UriSafeString(20)
                                                                  });

                                  x.Insert(new SelectedCharacteristic
                                           {
                                               CharacteristicId = characteristics1.Id,
                                               InstructionId = instruction1.Id
                                           });

                                  return new
                                         {
                                             Type1 = instructionType1,
                                             Type2 = instructionType2,
                                             Type3 = instructionType3,
                                             Instruction1 = instruction1,
                                             Instruction2 = instruction2,
                                             Characteristics1 = characteristics1,
                                             Characteristics2 = characteristics2
                                         };
                              });
        }
    }
}