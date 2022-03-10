using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail.CriteriaDetailEntry
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class Adding : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddEntry(BrowserType browserType)
        {
            ScenarioData scenario;

            using (var setup = new CriteriaDetailAddingDbSetup())
            {
                scenario = setup.SetUp();
            }

            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);
            var workflowDetails = new CriteriaDetailPage(driver);
            var entriesTopic = workflowDetails.EntriesTopic;

            var entryTobeAdded = Fixture.Prefix("test");
            var entryTobeAdded2 = Fixture.Prefix("test2");
            var entryTobeAdded3 = Fixture.Prefix("test3");
            var entrySeparatorTobeAdded = "--------" + Fixture.Prefix("Filling") + "--------";

            SignIn(driver, "/#/configuration/rules/workflows/" + scenario.CriteriaId);

            entriesTopic.Add();
            entriesTopic.CreateEntryModal.EntryDescription.Input(entryTobeAdded);
            entriesTopic.CreateEntryModal.Save();
            workflowDetails.InheritanceModal.WithoutApplyToChildren();
            workflowDetails.InheritanceModal.Proceed();

            var rowData = entriesTopic.GetDataForRow(entriesTopic.Grid.Rows.Count - 1);
            Assert.AreEqual(entryTobeAdded, rowData.Description, "since there was no selection, new entry should be added last");

            entriesTopic.Add();
            entriesTopic.CreateEntryModal.EntryDescription.Input(entryTobeAdded);
            entriesTopic.CreateEntryModal.Save();
            workflowDetails.InheritanceModal.Proceed();

            Assert.True(popups.AlertModal.Modal.Displayed, "Entry Already Exists");
            popups.AlertModal.Ok();

            entriesTopic.CreateEntryModal.EntryDescription.Clear();
            entriesTopic.CreateEntryModal.EntryDescription.Input(entryTobeAdded2);
            entriesTopic.CreateEntryModal.Save();
            workflowDetails.InheritanceModal.Proceed();

            //// click somewhere on the row (not checkbox), then row becomes selected
            entriesTopic.Grid.Cell(0, 1).ClickWithTimeout();

            entriesTopic.Add();
            entriesTopic.CreateEntryModal.EntryDescription.Input(entryTobeAdded3);
            entriesTopic.CreateEntryModal.Save();
            workflowDetails.InheritanceModal.Proceed();

            var rowData3 = entriesTopic.GetDataForRow(1);
            Assert.AreEqual(entryTobeAdded3, rowData3.Description, "since the first row was selected, new event should be added as second row");
            Assert.False(rowData3.IsSeparator, "entry added is a normal entry");

            entriesTopic.Add();
            entriesTopic.CreateEntryModal.EntryDescription.Input(entrySeparatorTobeAdded);
            entriesTopic.CreateEntryModal.AsSeparator();
            entriesTopic.CreateEntryModal.Save();
            workflowDetails.InheritanceModal.Proceed();

            var rowDataSeparator = entriesTopic.GetDataForRow(2);
            Assert.AreEqual(entrySeparatorTobeAdded, rowDataSeparator.Description, "separator entry added below the previous entry added");
            Assert.True(rowDataSeparator.IsSeparator, "Separator tick should be displayed in separator column");
        }
    }

}