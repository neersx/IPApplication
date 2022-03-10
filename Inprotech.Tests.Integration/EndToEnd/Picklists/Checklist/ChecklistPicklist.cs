using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Checklist
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ChecklistPicklist : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _checklistPicklistsDbSetup = new ChecklistPicklistDbSetup();
            _scenario = _checklistPicklistsDbSetup.Prepare();
        }

        ChecklistPicklistDbSetup _checklistPicklistsDbSetup;
        ChecklistPicklistDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckClientSideValidationForMandatoryAndMaxLength(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/checklist");

            var checklistPicklist = new PickList(driver).ById("checklist-picklist");
            checklistPicklist.SearchButton.Click();
            checklistPicklist.AddPickListItem();

            var pageDetails = new ChecklistDetailPage(driver);
            Assert.IsTrue(pageDetails.SaveButton.IsDisabled(), "Ensure Save is disabled");

            pageDetails.DefaultsTopic.Description.SendKeys("123456789012345678901234567890123456789012345678901");
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be maximum 50 characters");

            //https://github.com/mozilla/geckodriver/issues/1151
            pageDetails.Discard(); //edit mode discard
            pageDetails.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckForUniqueDescription(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingChecklist = _scenario.ExistingApplicationChecklist;

            SignIn(driver, "/#/configuration/general/validcombination/checklist");

            var checklistPicklist = new PickList(driver).ById("checklist-picklist");
            checklistPicklist.SearchButton.Click();
            checklistPicklist.AddPickListItem();

            var pageDetails = new ChecklistDetailPage(driver);

            var popups = new CommonPopups(driver);

            pageDetails.DefaultsTopic.Description.SendKeys(existingChecklist.Description);
            pageDetails.Save();

            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be unique");

            //https://github.com/mozilla/geckodriver/issues/1151
            pageDetails.Discard(); //edit mode discard
            pageDetails.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CopyChecklistDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/checklist");

            var checklistPicklist = new PickList(driver).ById("checklist-picklist");
            checklistPicklist.OpenPickList(ChecklistPicklistDbSetup.ExistingChecklist3);
            checklistPicklist.DuplicateRow(0);

            var pageDetails = new ChecklistDetailPage(driver);
            Assert.AreEqual(ChecklistPicklistDbSetup.ExistingChecklist3, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is same");
            Assert.IsFalse(pageDetails.DefaultsTopic.Renewal.Selected);

            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(ChecklistPicklistDbSetup.ChecklistToBeAdded);

            pageDetails.Save();

            checklistPicklist.SearchFor(ChecklistPicklistDbSetup.ChecklistToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ChecklistPicklistDbSetup.ChecklistToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");

        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class ChecklistPicklistDelete : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _checklistPicklistsDbSetup = new ChecklistPicklistDbSetup();
            _scenario = _checklistPicklistsDbSetup.Prepare();
        }

        ChecklistPicklistDbSetup _checklistPicklistsDbSetup;
        ChecklistPicklistDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteChecklistDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/checklist");

            var checklistPicklist = new PickList(driver).ById("checklist-picklist");
            checklistPicklist.OpenPickList(ChecklistPicklistDbSetup.ExistingChecklist2);
            checklistPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().WithJs().Click();

            checklistPicklist.SearchFor(ChecklistPicklistDbSetup.ExistingChecklist2);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, searchResults.Rows.Count, "Checklist should get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteChecklistAndThenClickNoOnConfirmation(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/checklist");

            var checklistPicklist = new PickList(driver).ById("checklist-picklist");
            checklistPicklist.OpenPickList(ChecklistPicklistDbSetup.ExistingChecklist2);
            checklistPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Cancel().ClickWithTimeout();

            checklistPicklist.SearchFor(ChecklistPicklistDbSetup.ExistingChecklist2);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Checklist value should not get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteChecklistDetailsWhichIsInUse(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            _checklistPicklistsDbSetup.AddValidChecklist(_scenario.ExistingApplicationChecklist);

            SignIn(driver, "/#/configuration/general/validcombination/checklist");

            var checklistPicklist = new PickList(driver).ById("checklist-picklist");
            checklistPicklist.OpenPickList(_scenario.ExistingApplicationChecklist.Description);
            checklistPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().WithJs().Click();

            popups.AlertModal.Ok();

            checklistPicklist.SearchFor(_scenario.ExistingApplicationChecklist.Description);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(3, searchResults.Rows.Count, "Checklist should get deleted");
            Assert.AreEqual(_scenario.ExistingApplicationChecklist.Description, searchResults.CellText(0, 0), "Ensure the text is updated");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class ChecklistPicklistEditing : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _checklistPicklistsDbSetup = new ChecklistPicklistDbSetup();
            _scenario = _checklistPicklistsDbSetup.Prepare();
        }

        ChecklistPicklistDbSetup _checklistPicklistsDbSetup;
        ChecklistPicklistDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddChecklistDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/checklist");

            var checklistPicklist = new PickList(driver).ById("checklist-picklist");
            checklistPicklist.SearchButton.Click();
            checklistPicklist.AddPickListItem();

            var pageDetails = new ChecklistDetailPage(driver);
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Description is equal");
            Assert.IsFalse(pageDetails.DefaultsTopic.Renewal.Selected, "Renewal checkbox exists and is unchecked");
            Assert.IsFalse(pageDetails.DefaultsTopic.Examination.Selected, "Examination checkbox exists and is unchecked");
            Assert.IsTrue(pageDetails.DefaultsTopic.Other.Selected, "Other checkbox exists and is checked");

            pageDetails.DefaultsTopic.Description.SendKeys(ChecklistPicklistDbSetup.ChecklistToBeAdded);
            pageDetails.DefaultsTopic.Renewal.WithJs().Click();
            pageDetails.Save();

            Assert.AreEqual(ChecklistPicklistDbSetup.ChecklistToBeAdded, checklistPicklist.SearchGrid.CellText(0, 0), "Ensure the text is updated");
            Assert.IsTrue(checklistPicklist.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");

            checklistPicklist.SearchFor(ChecklistPicklistDbSetup.ChecklistToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ChecklistPicklistDbSetup.ChecklistToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DiscardCancelDialogOnChecklistChange(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/checklist");

            var checklistPicklist = new PickList(driver).ById("checklist-picklist");
            checklistPicklist.OpenPickList(_scenario.ChecklistName);
            checklistPicklist.AddPickListItem();

            var pageDetails = new ChecklistDetailPage(driver);

            pageDetails.DefaultsTopic.Description.SendKeys("A");

            pageDetails.DefaultsTopic.Renewal.WithJs().Click();
            pageDetails.Discard();

            var popup = new CommonPopups(driver);
            popup.DiscardChangesModal.Cancel();
            Assert.AreEqual(pageDetails.DefaultsTopic.Description.GetAttribute("value"), "A", "Code is not lost");

            pageDetails.Discard();
            popup.DiscardChangesModal.Discard();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Name("value")));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditAndSaveChecklistDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingChecklist = _scenario.ExistingApplicationChecklist;

            SignIn(driver, "/#/configuration/general/validcombination/checklist");

            var checklistPicklist = new PickList(driver).ById("checklist-picklist");
            checklistPicklist.OpenPickList(_scenario.ChecklistName);
            checklistPicklist.EditRow(0);

            var pageDetails = new ChecklistDetailPage(driver);
            Assert.AreEqual(existingChecklist.Description, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is equal");
            Assert.AreEqual(existingChecklist.ChecklistTypeFlag == 1, pageDetails.DefaultsTopic.Renewal.Selected);

            var editedName = existingChecklist.Description + " edited";
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(editedName);
            pageDetails.Save();

            checklistPicklist.SearchFor(editedName);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Only one row is returned");
            Assert.AreEqual(editedName, searchResults.CellText(0, 0), "Ensure the text is updated");
        }
    }
}