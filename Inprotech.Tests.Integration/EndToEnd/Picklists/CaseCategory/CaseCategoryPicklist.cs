using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseCategory
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseCategoryPicklist : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _caseCategoryPicklistsDbSetup = new CaseCategoryPicklistDbSetup();
            _scenario = _caseCategoryPicklistsDbSetup.Prepare();
        }

        CaseCategoryPicklistDbSetup _caseCategoryPicklistsDbSetup;
        CaseCategoryPicklistDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckClientSideValidationForMandatoryAndMaxLength(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/category");

            var caseType = new PickList(driver).ByName(string.Empty, "caseType");
            caseType.EnterAndSelect("Properties");

            var caseCategoryPicklist = new PickList(driver).ById("case-category-picklist");
            caseCategoryPicklist.SearchButton.Click();
            caseCategoryPicklist.AddPickListItem();

            var pageDetails = new CaseCategoryDetailPage(driver);
            Assert.IsTrue(pageDetails.SaveButton.IsDisabled(), "Ensure Save is disabled");

            pageDetails.DefaultsTopic.Code.SendKeys("8");
            driver.WaitForAngular();
            pageDetails.Save();

            Assert.IsTrue(new TextField(driver, "value").HasError, "Description is mandatory");

            pageDetails.DefaultsTopic.Code.Clear();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code is mandatory");

            pageDetails.DefaultsTopic.Code.SendKeys("AAA");
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code should be maximum 2 characters");

            pageDetails.DefaultsTopic.Description.SendKeys("123456789012345678901234567890123456789012345678901");
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be maximum 50 characters");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("8");
            Assert.IsFalse(new TextField(driver, "code").HasError);

            driver.WaitForAngular();
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys("AAA");
            Assert.IsFalse(new TextField(driver, "value").HasError);

            //https://github.com/mozilla/geckodriver/issues/1151
            pageDetails.Discard(); //edit mode discard
            pageDetails.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckForUniqueCodeAndDescription(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingCaseCategory = _scenario.ExistingApplicationCaseCategory;

            SignIn(driver, "/#/configuration/general/validcombination/category");

            var caseType = new PickList(driver).ByName(string.Empty, "caseType");
            caseType.EnterAndSelect("Oppositions/Owner");

            var caseCategoryPicklist = new PickList(driver).ById("case-category-picklist");
            caseCategoryPicklist.SearchButton.Click();
            caseCategoryPicklist.AddPickListItem();

            var pageDetails = new CaseCategoryDetailPage(driver);

            pageDetails.DefaultsTopic.Code.SendKeys(existingCaseCategory.CaseCategoryId);
            pageDetails.DefaultsTopic.Description.SendKeys("abcd");
            pageDetails.Save();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code should be unique");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("1");
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(existingCaseCategory.Name);
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
        public void CopyCaseCategoryDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/category");

            var caseType = new PickList(driver).ByName(string.Empty, "caseType");
            caseType.EnterAndSelect("Oppositions/Owner");

            var caseCategoryPicklist = new PickList(driver).ById("case-category-picklist");
            caseCategoryPicklist.OpenPickList(CaseCategoryPicklistDbSetup.ExistingCaseCategory2);
            caseCategoryPicklist.DuplicateRow(0);

            var pageDetails = new CaseCategoryDetailPage(driver);
            Assert.AreEqual("2", pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is same");
            Assert.IsNull(pageDetails.DefaultsTopic.Code.GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(CaseCategoryPicklistDbSetup.ExistingCaseCategory2, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is same");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("8");
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(CaseCategoryPicklistDbSetup.CaseCategoryToBeAdded);

            pageDetails.Save();

            caseCategoryPicklist.SearchFor(CaseCategoryPicklistDbSetup.CaseCategoryToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(CaseCategoryPicklistDbSetup.CaseCategoryToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("8", searchResults.CellText(0, 1), "Ensure the text is updated");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseCategoryPicklistDelete : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _caseCategoryPicklistsDbSetup = new CaseCategoryPicklistDbSetup();
            _scenario = _caseCategoryPicklistsDbSetup.Prepare();
        }

        CaseCategoryPicklistDbSetup _caseCategoryPicklistsDbSetup;
        CaseCategoryPicklistDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteCaseCategoryDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/category");

            var caseType = new PickList(driver).ByName(string.Empty, "caseType");
            caseType.EnterAndSelect("Oppositions/Owner");

            var caseCategoryPicklist = new PickList(driver).ById("case-category-picklist");
            caseCategoryPicklist.OpenPickList(CaseCategoryPicklistDbSetup.ExistingCaseCategory2);
            caseCategoryPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().WithJs().Click();

            caseCategoryPicklist.SearchFor(CaseCategoryPicklistDbSetup.ExistingCaseCategory2);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, searchResults.Rows.Count, "Case Category should get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteCaseCategoryAndThenClickNoOnConfirmation(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/category");

            var caseType = new PickList(driver).ByName(string.Empty, "caseType");
            caseType.EnterAndSelect("Oppositions/Owner");

            var caseCategoryPicklist = new PickList(driver).ById("case-category-picklist");
            caseCategoryPicklist.OpenPickList(CaseCategoryPicklistDbSetup.ExistingCaseCategory2);
            caseCategoryPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Cancel().ClickWithTimeout();

            caseCategoryPicklist.SearchFor(CaseCategoryPicklistDbSetup.ExistingCaseCategory2);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Case Category value should not get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteCaseCategoryDetailsWhichIsInUse(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            _caseCategoryPicklistsDbSetup.AddValidCaseCategory(_scenario.ExistingApplicationCaseCategory);

            SignIn(driver, "/#/configuration/general/validcombination/category");

            var caseType = new PickList(driver).ByName(string.Empty, "caseType");
            caseType.EnterAndSelect("Oppositions/Owner");

            var caseCategoryPicklist = new PickList(driver).ById("case-category-picklist");
            caseCategoryPicklist.OpenPickList(_scenario.ExistingApplicationCaseCategory.Name);
            caseCategoryPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().WithJs().Click();
            driver.WaitForAngular();
            popups.AlertModal.Ok();

            caseCategoryPicklist.SearchFor(_scenario.ExistingApplicationCaseCategory.Name);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(3, searchResults.Rows.Count, "Case Category should get deleted");
            Assert.AreEqual(_scenario.ExistingApplicationCaseCategory.Name, searchResults.CellText(0, 0), "Ensure the text is updated");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseCategoryPicklistEditing : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _caseCategoryPicklistsDbSetup = new CaseCategoryPicklistDbSetup();
            _scenario = _caseCategoryPicklistsDbSetup.Prepare();
        }

        CaseCategoryPicklistDbSetup _caseCategoryPicklistsDbSetup;
        CaseCategoryPicklistDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]

        public void AddCaseCategoryDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/category");

            var caseType = new PickList(driver).ByName(string.Empty, "caseType");
            caseType.EnterAndSelect("Properties");

            var caseCategoryPicklist = new PickList(driver).ById("case-category-picklist");
            caseCategoryPicklist.SearchButton.Click();
            caseCategoryPicklist.AddPickListItem();

            var pageDetails = new CaseCategoryDetailPage(driver);
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Code.GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Description is equal");
            pageDetails.DefaultsTopic.Code.SendKeys("8");
            pageDetails.DefaultsTopic.Description.SendKeys(CaseCategoryPicklistDbSetup.CaseCategoryToBeAdded);
            pageDetails.Save();

            Assert.AreEqual(CaseCategoryPicklistDbSetup.CaseCategoryToBeAdded, caseCategoryPicklist.SearchGrid.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("8", caseCategoryPicklist.SearchGrid.CellText(0, 1), "Ensure the text is updated");
            Assert.IsTrue(caseCategoryPicklist.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");

            caseCategoryPicklist.SearchFor(CaseCategoryPicklistDbSetup.CaseCategoryToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(CaseCategoryPicklistDbSetup.CaseCategoryToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("8", searchResults.CellText(0, 1), "Ensure the text is updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DiscardCancelDialogOnCaseCategoryChange(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/category");

            var caseType = new PickList(driver).ByName(string.Empty, "caseType");
            caseType.EnterAndSelect("Properties");

            var caseCategoryPicklist = new PickList(driver).ById("case-category-picklist");
            caseCategoryPicklist.OpenPickList(_scenario.CaseCategoryName);
            caseCategoryPicklist.AddPickListItem();

            var pageDetails = new CaseCategoryDetailPage(driver);

            pageDetails.DefaultsTopic.Code.SendKeys("8");
            pageDetails.Discard();

            var popup = new CommonPopups(driver);
            popup.DiscardChangesModal.Cancel();
            Assert.AreEqual(pageDetails.DefaultsTopic.Code.GetAttribute("value"), "8", "Code is not lost");

            pageDetails.Discard();
            popup.DiscardChangesModal.Discard();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Name("code")));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditAndSaveCaseCategoryDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingCaseCategory = _scenario.ExistingApplicationCaseCategory;

            SignIn(driver, "/#/configuration/general/validcombination/category");

            var caseType = new PickList(driver).ByName(string.Empty, "caseType");
            caseType.EnterAndSelect("Oppositions/Owner");

            var caseCategoryPicklist = new PickList(driver).ById("case-category-picklist");
            caseCategoryPicklist.OpenPickList(_scenario.CaseCategoryName);
            caseCategoryPicklist.EditRow(0);

            var pageDetails = new CaseCategoryDetailPage(driver);
            Assert.AreEqual(existingCaseCategory.CaseCategoryId, pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is equal");
            Assert.IsTrue(pageDetails.DefaultsTopic.Code.GetAttribute("disabled").Equals("true"), "Ensure Code is disabled");
            Assert.AreEqual(existingCaseCategory.Name, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is equal");

            var editedName = existingCaseCategory.Name + " edited";
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(editedName);
            pageDetails.Save();

            caseCategoryPicklist.SearchFor(editedName);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Only one row is returned");
            Assert.AreEqual(editedName, searchResults.CellText(0, 0), "Ensure the text is updated");
        }
    }
}
