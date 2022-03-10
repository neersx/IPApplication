using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Action
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ActionPicklist : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _actionPicklistsDbSetup = new ActionPicklistsDbSetup();
            _scenario = _actionPicklistsDbSetup.Prepare();
        }

        ActionPicklistsDbSetup _actionPicklistsDbSetup;
        ActionPicklistsDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckClientSideValidationForMandatoryAndMaxLength(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var actionPicklist = new PickList(driver).ById("action-picklist");
            actionPicklist.SearchButton.Click();
            actionPicklist.AddPickListItem();

            var pageDetails = new ActionDetailPage(driver);
            Assert.IsTrue(pageDetails.SaveButton.GetAttribute("disabled").Equals("true"), "Ensure Save is disabled");

            pageDetails.DefaultsTopic.Code(driver).SendKeys("A");
            driver.WaitForAngular();
            pageDetails.SaveButton.Click();

            Assert.IsTrue(new TextField(driver, "value").HasError, "Description is mandatory");

            pageDetails.DefaultsTopic.Code(driver).Clear();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code is mandatory");

            pageDetails.DefaultsTopic.ImportanceLevel.Input.SelectByText(string.Empty);
            Assert.IsTrue(pageDetails.DefaultsTopic.ImportanceLevel.HasError, "Importance Level is mandatory");

            pageDetails.DefaultsTopic.Code(driver).SendKeys("AAA");
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code should be maximum 2 characters");

            pageDetails.DefaultsTopic.Description(driver).SendKeys("123456789012345678901234567890123456789012345678901");
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be maximum 50 characters");

            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Code(driver).SendKeys("A");
            Assert.IsFalse(new TextField(driver, "code").HasError);

            driver.WaitForAngular();
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys("AAA");
            Assert.IsFalse(new TextField(driver, "value").HasError);

            pageDetails.Discard(); // picklist edit mode discard
            pageDetails.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckForUniqueCodeAndDescription(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingAction = _scenario.ExistingApplicationAction;

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var actionPicklist = new PickList(driver).ById("action-picklist");
            actionPicklist.SearchButton.Click();
            actionPicklist.AddPickListItem();

            var pageDetails = new ActionDetailPage(driver);

            pageDetails.DefaultsTopic.Code(driver).SendKeys(existingAction.Code);
            pageDetails.DefaultsTopic.Description(driver).SendKeys("abcd");
            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code should be unique");

            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Code(driver).SendKeys("A");
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(existingAction.Name);
            pageDetails.SaveButton.ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be unique");

            pageDetails.Discard(); // picklist edit mode discard
            pageDetails.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CopyActionDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var actionPicklist = new PickList(driver).ById("action-picklist");
            actionPicklist.OpenPickList(ActionPicklistsDbSetup.ExistingAction3);
            actionPicklist.DuplicateRow(0);

            var pageDetails = new ActionDetailPage(driver);

            Assert.AreEqual("3", pageDetails.DefaultsTopic.Code(driver).GetAttribute("value"), "Ensure Code is same");
            Assert.IsNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(ActionPicklistsDbSetup.ExistingAction3, pageDetails.DefaultsTopic.Description(driver).GetAttribute("value"), "Ensure Name is same");
            Assert.IsFalse(pageDetails.DefaultsTopic.Renewal(driver).Selected);

            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Code(driver).SendKeys("A");
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(ActionPicklistsDbSetup.ActionToBeAdded);
            pageDetails.DefaultsTopic.ImportanceLevel.Input.SelectByText("Critical");
            pageDetails.SaveButton.ClickWithTimeout();
            actionPicklist.SearchFor(ActionPicklistsDbSetup.ActionToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ActionPicklistsDbSetup.ActionToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("A", searchResults.CellText(0, 1), "Ensure the text is updated");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class ActionPicklistDelete : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _actionPicklistsDbSetup = new ActionPicklistsDbSetup();
            _scenario = _actionPicklistsDbSetup.Prepare();
        }

        ActionPicklistsDbSetup _actionPicklistsDbSetup;
        ActionPicklistsDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteActionDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var actionPicklist = new PickList(driver).ById("action-picklist");
            actionPicklist.OpenPickList(ActionPicklistsDbSetup.ExistingAction2);
            actionPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            driver.WaitForAngular();

            actionPicklist.SearchFor(ActionPicklistsDbSetup.ExistingAction2);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, searchResults.Rows.Count, "Action should get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteActionAndThenClickNoOnConfirmation(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var actionPicklist = new PickList(driver).ById("action-picklist");
            actionPicklist.OpenPickList(ActionPicklistsDbSetup.ExistingAction2);
            actionPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Cancel().ClickWithTimeout();

            actionPicklist.SearchFor(ActionPicklistsDbSetup.ExistingAction2);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Action value should not get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteActionDetailsWhichIsInUse(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            _actionPicklistsDbSetup.AddValidAction(_scenario.ExistingApplicationAction);

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var actionPicklist = new PickList(driver).ById("action-picklist");
            actionPicklist.OpenPickList(_scenario.ExistingApplicationAction.Name);
            actionPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            popups.AlertModal.Ok();

            actionPicklist.SearchFor(_scenario.ExistingApplicationAction.Name);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(3, searchResults.Rows.Count, "Action should get deleted");
            Assert.AreEqual(_scenario.ExistingApplicationAction.Name, searchResults.CellText(0, 0), "Ensure the text is updated");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class ActionPicklistEditing : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _actionPicklistsDbSetup = new ActionPicklistsDbSetup();
            _scenario = _actionPicklistsDbSetup.Prepare();
        }

        ActionPicklistsDbSetup _actionPicklistsDbSetup;
        ActionPicklistsDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddActionDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var actionPicklist = new PickList(driver).ById("action-picklist");
            actionPicklist.SearchButton.Click();
            actionPicklist.AddPickListItem();

            var pageDetails = new ActionDetailPage(driver);
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Code(driver).GetAttribute("value"), "Ensure Code is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description(driver).GetAttribute("value"), "Ensure Description is equal");
            Assert.AreEqual("1", pageDetails.DefaultsTopic.Cycles(driver).GetAttribute("value"), "Ensure Cycles is equal");

            Assert.AreEqual("9", pageDetails.DefaultsTopic.ImportanceLevel.Value, "Ensure Importance Level is equal");
            Assert.IsFalse(pageDetails.DefaultsTopic.Renewal(driver).Selected, "Renewal checkbox exists and is unchecked");
            Assert.IsFalse(pageDetails.DefaultsTopic.Examination(driver).Selected, "Examination checkbox exists and is unchecked");
            Assert.IsTrue(pageDetails.DefaultsTopic.Other(driver).Selected, "Other checkbox exists and is checked");

            pageDetails.DefaultsTopic.Code(driver).SendKeys("A");
            pageDetails.DefaultsTopic.Description(driver).SendKeys(ActionPicklistsDbSetup.ActionToBeAdded);
            pageDetails.DefaultsTopic.UnlimitedCycles(driver).WithJs().Click();
            pageDetails.DefaultsTopic.Renewal(driver).WithJs().Click();
            pageDetails.SaveButton.ClickWithTimeout();

            actionPicklist.SearchFor(ActionPicklistsDbSetup.ActionToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ActionPicklistsDbSetup.ActionToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("A", searchResults.CellText(0, 1), "Ensure the text is updated");
            Assert.AreEqual("9999", searchResults.CellText(0, 2), "Ensure the text is updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DiscardCancelDialogOnActionChange(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var actionPicklist = new PickList(driver).ById("action-picklist");
            actionPicklist.OpenPickList(_scenario.ActionName);
            actionPicklist.AddPickListItem();

            var pageDetails = new ActionDetailPage(driver);

            pageDetails.DefaultsTopic.Code(driver).SendKeys("A");

            pageDetails.DefaultsTopic.Renewal(driver).WithJs().Click();
            pageDetails.Discard();

            var popup = new CommonPopups(driver);
            popup.DiscardChangesModal.Cancel();
            Assert.AreEqual(pageDetails.DefaultsTopic.Code(driver).GetAttribute("value"), "A", "Code is not lost");

            pageDetails.Discard();
            popup.DiscardChangesModal.Discard();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Name("code")));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditAndSaveActionDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingAction = _scenario.ExistingApplicationAction;

            SignIn(driver, "/#/configuration/general/validcombination/action");

            var actionPicklist = new PickList(driver).ById("action-picklist");
            actionPicklist.OpenPickList(_scenario.ActionName);
            actionPicklist.EditRow(0);

            var pageDetails = new ActionDetailPage(driver);
            Assert.AreEqual(existingAction.Code, pageDetails.DefaultsTopic.Code(driver).GetAttribute("value"), "Ensure Code is equal");
            Assert.IsTrue(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled").Equals("true"), "Ensure Code is disabled");
            Assert.AreEqual(existingAction.Name, pageDetails.DefaultsTopic.Description(driver).GetAttribute("value"), "Ensure Name is equal");
            Assert.AreEqual(existingAction.ActionType == 1, pageDetails.DefaultsTopic.Renewal(driver).Selected);

            var editedName = existingAction.Name + " edited";
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(editedName);
            pageDetails.DefaultsTopic.ImportanceLevel.Input.SelectByText("Critical");
            pageDetails.SaveButton.ClickWithTimeout();

            actionPicklist.SearchFor(editedName);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Only one row is returned");
            Assert.AreEqual(editedName, searchResults.CellText(0, 0), "Ensure the text is updated");
        }
    }
}