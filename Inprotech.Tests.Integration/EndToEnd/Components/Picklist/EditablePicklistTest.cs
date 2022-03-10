using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Picklists.EventGroup;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Configuration;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Components.Picklist
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EditablePicklistTest : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddUpdateDeletePicklist(BrowserType browserType)
        {
            var setup = Setup();
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/picklist");

            var eventGroupPl = new PickList(driver).ByName("e2eEventGroup");
            eventGroupPl.OpenPickList();
            eventGroupPl.SearchFor(setup.EventGroupDescription);
            eventGroupPl.SearchGrid.ClickEdit(0);
            
            var eventGroupModal = new EventGroupPickListModal(driver);
            eventGroupModal.Description.Clear();
            eventGroupModal.Description.SendKeys("modified");
            eventGroupModal.Save();
            eventGroupModal.Discard();

            MakeSureModifiedAndHighlighted(eventGroupPl, 0, "Description");
            
            eventGroupPl.AddPickListItem();

            var addDesc = Fixture.String(50);
            var addCode = Fixture.String(10);
            eventGroupModal.Description.SendKeys(addDesc);
            eventGroupModal.UserCode.SendKeys(addCode);
            eventGroupModal.Save();

            Assert.AreEqual(addDesc, eventGroupPl.SearchGrid.CellText(0, 0), "New Description should appear in first row");
            Assert.AreEqual(addCode, eventGroupPl.SearchGrid.CellText(0, 1), "New Code should appear in first row");
            Assert.IsTrue(eventGroupPl.SearchGrid.RowIsHighlighted(0), "Added row should be highlighted");

            var editDesc = Fixture.String(10);
            var editCode = Fixture.String(5);
            eventGroupPl.SearchGrid.ClickEdit(0);
            eventGroupModal = new EventGroupPickListModal(driver);
            eventGroupModal.Description.Clear();
            eventGroupModal.UserCode.Clear();

            eventGroupModal.Description.SendKeys(editDesc);
            eventGroupModal.UserCode.SendKeys(editCode);
            eventGroupModal.Save();
            eventGroupModal.Discard();

            Assert.AreEqual(editDesc, eventGroupPl.SearchGrid.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual(editCode, eventGroupPl.SearchGrid.CellText(0, 1), "Ensure the text is updated");
            Assert.IsTrue(eventGroupPl.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");

            eventGroupPl.DeleteRow(0);
            
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().Click();

            eventGroupPl.SearchFor(editDesc);
            Assert.AreEqual(0, eventGroupPl.SearchGrid.Rows.Count, "Event group should be deleted.");
        }

        void MakeSureModifiedAndHighlighted(PickList picklist, int rowIndex, string colName, string modifiedText = "modified")
        {
            var colIndex = picklist.SearchGrid.FindColByName(colName);
            Assert.AreEqual(modifiedText, picklist.SearchGrid.Cell(rowIndex, colIndex).Text, "After saving maintenance dialog, updated data should display");
            Assert.IsTrue(picklist.SearchGrid.RowIsHighlighted(rowIndex), "After saving maintenance dialog, edited row should be highlighted");
        }

        static int ClickEditInPicklistRow(PickList picklist, string columnName, string cellValue)
        {
            var row = picklist.SearchGrid.FindRow(columnName, cellValue, out int rowIndex);
            Assert.IsNotNull(row, "we are going to click this row so it should be found");
            picklist.SearchGrid.ClickEdit(rowIndex);
            return rowIndex;
        }

        PicklistTestSetup Setup()
        {
            using (var setup = new DbSetup())
            {

                var eventGroupDescription = setup.InsertWithNewId(new TableCode
                {
                    TableTypeId = (short) ProtectedTableTypes.EventGroup,
                    Name = Fixture.String(5)
                }).Name;

                return new PicklistTestSetup
                {
                    EventGroupDescription = eventGroupDescription
                };
            }
        }
    }

    class PicklistTestSetup
    {
        public string EventGroupDescription { get; set; }
    }
}