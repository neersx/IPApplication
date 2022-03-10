using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Picklists.InstructionType;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Configuration;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Components.Picklist
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class NgEditablePicklistTest : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddUpdateDeletePicklist(BrowserType browserType)
        {
            var setup = Setup();
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/ipx-picklist");

            var instructionType = new AngularPicklist(driver).ByName("e2eInstructionType");
            instructionType.OpenPickList();
            instructionType.SearchFor(setup.InstructionType);
            instructionType.SearchGrid.ClickEdit(0);

            var instructionModal = new AngularInstructionTypePicklistModal(driver);
            instructionModal.Description.Text = string.Empty;
            instructionModal.Description.Text = "modified";
            instructionModal.Apply();

            //TODO Future stories
            //MakeSureModifiedAndHighlighted(eventGroupPl, 0, "Description");

            instructionType.AddAngularPicklistItem();

            var addDesc = Fixture.String(5);
            var addCode = Fixture.String(3);
            instructionModal.Description.Text = addDesc;
            instructionModal.Code.Text = addCode;
            instructionModal.RecordedAgainst.Text = "Author";
            instructionModal.Apply();

            instructionType.SearchFor(addCode);

            Assert.AreEqual(addDesc, instructionType.SearchGrid.CellText(0, 1), "New Description should appear in first row");
            Assert.AreEqual(addCode, instructionType.SearchGrid.CellText(0, 0), "New Code should appear in first row");
            //TODO Future stories
            //Assert.IsTrue(instructionType.SearchGrid.RowIsHighlighted(0), "Added row should be highlighted");

            var editDesc = Fixture.String(5);
            instructionType.SearchGrid.ClickEdit(0);
            instructionModal = new AngularInstructionTypePicklistModal(driver);
            instructionModal.Description.Text = string.Empty;

            instructionModal.Description.Text = editDesc;
            instructionModal.Apply();

            instructionType.SearchFor(addCode);

            Assert.AreEqual(editDesc, instructionType.SearchGrid.CellText(0, 1), "Ensure the text is updated");
            //TODO Future stories
            //Assert.IsTrue(eventGroupPl.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");

            instructionType.SearchGrid.ClickDelete(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmNgDeleteModal.Delete.Click();

            instructionType.SearchFor(editDesc);
            Assert.AreEqual(0, instructionType.SearchGrid.Rows.Count, "Event group should be deleted.");
        }

        void MakeSureModifiedAndHighlighted(AngularPicklist picklist, int rowIndex, string colName, string modifiedText = "modified")
        {
            var colIndex = picklist.SearchGrid.FindColByText(colName);
            Assert.AreEqual(modifiedText, picklist.SearchGrid.Cell(rowIndex, colIndex).Text, "After saving maintenance dialog, updated data should display");
            Assert.IsTrue(picklist.SearchGrid.RowIsHighlighted(rowIndex), "After saving maintenance dialog, edited row should be highlighted");
        }

        static int ClickEditInPicklistRow(AngularPicklist picklist, string columnName, string cellValue)
        {
            var row = picklist.SearchGrid.FindRow(columnName, cellValue, out int rowIndex);
            Assert.IsNotNull(row, "we are going to click this row so it should be found");
            picklist.SearchGrid.ClickEdit(rowIndex);
            return rowIndex;
        }

        NgPicklistTestSetup Setup()
        {
            using (var setup = new DbSetup())
            {

                var eventGroupDescription = setup.InsertWithNewId(new TableCode
                {
                    TableTypeId = (short)ProtectedTableTypes.EventGroup,
                    Name = Fixture.String(5)
                }).Name;

                return new NgPicklistTestSetup
                {
                    EventGroupDescription = eventGroupDescription
                };
            }
        }
    }

    class NgPicklistTestSetup
    {
        public string EventGroupDescription { get; set; }
        public string InstructionType { get; set; }
    }
}