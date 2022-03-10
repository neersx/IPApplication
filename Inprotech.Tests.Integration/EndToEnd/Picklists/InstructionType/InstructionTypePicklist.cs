using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.StandingInstructions;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.InstructionType
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class InstructionTypePicklist : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddUpdateDeleteInstructionType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var user = new Users()
                .WithPermission(ApplicationTask.MaintainBaseInstructions)
                .Create();

            var data = SetupScenarioData();

            SignIn(driver, "/#/configuration/general/standinginstructions", user.Username, user.Password);

            var picklist = new PickList(driver).ById("instructiontype-picklist");
            picklist.OpenPickList();
            picklist.AddPickListItem();

            var code = Fixture.UriSafeString(3);
            var description = Fixture.UriSafeString(20);

            var popups = new CommonPopups(driver);
            var modal = new InstructionTypePicklistModal(driver);

            Assert.True(string.IsNullOrWhiteSpace(modal.Code.Text), "Should display empty");
            Assert.True(string.IsNullOrWhiteSpace(modal.Description.Text), "Should display description empty");

            modal.Code.Text = code;
            modal.Description.Text = description;
            modal.RecordedAgainst.Input.SelectByText(data.NameType.Name);
            modal.RestrictedBy.Input.SelectByText(data.NameType.Name);
            modal.Apply();

            picklist.SearchFor(code);

            Assert.AreEqual(1, picklist.SearchGrid.Rows.Count);
            Assert.AreEqual(code, picklist.SearchGrid.CellText(0, 0), "Should show added code");
            Assert.AreEqual(description, picklist.SearchGrid.CellText(0, 1), "Should show added description");
            
            picklist.EditRow(0);

            modal = new InstructionTypePicklistModal(driver);

            Assert.AreEqual(code, modal.Code.Text, $"Should fill existing code '{code}' for edit");
            Assert.AreEqual(description, modal.Description.Text, $"Should fill existing description '{description}' for edit");
            Assert.AreEqual(data.NameType.Name, modal.RecordedAgainst.Text, $"Should fill existing recorded against '{data.NameType.Name}' for edit");
            Assert.AreEqual(data.NameType.Name, modal.RestrictedBy.Text, $"Should fill existing restricted by '{data.NameType.Name}' for edit");

            var newDescription = Fixture.UriSafeString(20);
            modal.Description.Text = newDescription;
            modal.Apply();

            Assert.AreEqual(newDescription, picklist.SearchGrid.CellText(0, 1), "Should show edited description");

            picklist.SearchFor(code);
            picklist.DeleteRow(0);

            popups.ConfirmDeleteModal.Delete().WithJs().Click();
            
            picklist.SearchFor(code);
            Assert.IsEmpty(picklist.SearchGrid.Rows, $"Not in used Instruction Type '{code}' should get deleted");
        }

        static dynamic SetupScenarioData()
        {
            return DbSetup.Do(x =>
                              {
                                  var itb = new InstructionTypeBuilder(x.DbContext);

                                  var nt = new NameTypeBuilder(x.DbContext).Create();

                                  var instructionType1 = itb.Create('A' + Fixture.String(5));
                                  var instructionType2 = itb.Create('B' + Fixture.String(5));
                                  var instructionType3 = itb.Create('C' + Fixture.String(5));

                                  var instruction1 = x.InsertWithNewId(new Instruction
                                                                       {
                                                                           InstructionTypeCode = instructionType1.Code,
                                                                           Description = 'A' + Fixture.UriSafeString(20)
                                                                       });

                                  var instruction2 = x.InsertWithNewId(new Instruction
                                                                       {
                                                                           InstructionTypeCode = instructionType1.Code,
                                                                           Description = 'B' + Fixture.UriSafeString(20)
                                                                       });

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
                                             NameType = nt,
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