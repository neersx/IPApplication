using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Basis
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class BasisPicklist : IntegrationTest
    {
        [SetUp]
        public void ClassInit()
        {
            _basisPicklistsDbSetup = new BasisPicklistsDbSetup();
            _scenario = _basisPicklistsDbSetup.Prepare();
        }

        BasisPicklistsDbSetup _basisPicklistsDbSetup;
        BasisPicklistsDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckClientSideValidationForMandatoryAndMaxLength(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/basis");

            var basisPicklist = new PickList(driver).ByName(string.Empty, "basis");
            basisPicklist.SearchButton.Click();
            basisPicklist.AddPickListItem();

            var pageDetails = new BasisDetailPage(driver);
            Assert.IsTrue(pageDetails.SaveButton.GetAttribute("disabled").Equals("true"), "Ensure Save is disabled");

            pageDetails.DefaultsTopic.Code.SendKeys("A");
            driver.WaitForAngular();
            pageDetails.SaveButton.Click();

            Assert.IsTrue(new TextField(driver, "value").HasError, "Description is mandatory");

            pageDetails.DefaultsTopic.Code.Clear();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code is mandatory");

            pageDetails.DefaultsTopic.Code.SendKeys("AAA");
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code should be maximum 2 characters");

            pageDetails.DefaultsTopic.Description.SendKeys("123456789012345678901234567890123456789012345678901");
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be maximum 50 characters");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("A");
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
            var existingBasis = _scenario.ExistingApplicationBasis;

            SignIn(driver, "/#/configuration/general/validcombination/basis");

            var basisPicklist = new PickList(driver).ByName(string.Empty, "basis");
            basisPicklist.SearchButton.Click();
            basisPicklist.AddPickListItem();

            var pageDetails = new BasisDetailPage(driver);

            pageDetails.DefaultsTopic.Code.SendKeys(existingBasis.Code);
            pageDetails.DefaultsTopic.Description.SendKeys("abcd");
            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "code").HasError, "Code should be unique");

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("A");
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(existingBasis.Name);
            pageDetails.SaveButton.ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "value").HasError, "Description should be unique");

            //https://github.com/mozilla/geckodriver/issues/1151
            pageDetails.Discard(); //edit mode discard
            pageDetails.Discard(); // discard confirm.
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CopyBasisDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/basis");

            var basisPicklist = new PickList(driver).ByName(string.Empty, "basis");
            basisPicklist.OpenPickList(BasisPicklistsDbSetup.ExistingBasis3);
            basisPicklist.DuplicateRow(0);

            var pageDetails = new BasisDetailPage(driver);
            Assert.AreEqual("3", pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is same");
            Assert.IsNull(pageDetails.DefaultsTopic.Code.GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(BasisPicklistsDbSetup.ExistingBasis3, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is same");
            Assert.IsTrue(pageDetails.DefaultsTopic.Convention.Selected);

            pageDetails.DefaultsTopic.Code.Clear();
            pageDetails.DefaultsTopic.Code.SendKeys("A");
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(BasisPicklistsDbSetup.BasisToBeAdded);

            pageDetails.SaveButton.ClickWithTimeout();

            basisPicklist.SearchFor(BasisPicklistsDbSetup.BasisToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(BasisPicklistsDbSetup.BasisToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("A", searchResults.CellText(0, 1), "Ensure the text is updated");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class BasisPicklistDelete : IntegrationTest
    {
        [SetUp]
        public void ClassInit()
        {
            _basisPicklistsDbSetup = new BasisPicklistsDbSetup();
            _scenario = _basisPicklistsDbSetup.Prepare();
        }

        BasisPicklistsDbSetup _basisPicklistsDbSetup;
        BasisPicklistsDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteBasisDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/basis");

            var basisPicklist = new PickList(driver).ByName(string.Empty, "basis");
            basisPicklist.OpenPickList(BasisPicklistsDbSetup.ExistingBasis2);
            basisPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().WithJs().Click();

            basisPicklist.SearchFor(BasisPicklistsDbSetup.ExistingBasis2);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, searchResults.Rows.Count, "Basis should get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteBasisAndThenClickNoOnConfirmation(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/basis");

            var basisPicklist = new PickList(driver).ByName(string.Empty, "basis");
            basisPicklist.OpenPickList(BasisPicklistsDbSetup.ExistingBasis2);
            basisPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Cancel().ClickWithTimeout();

            basisPicklist.SearchFor(BasisPicklistsDbSetup.ExistingBasis2);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Basis value should not get deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteBasisDetailsWhichIsInUse(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            _basisPicklistsDbSetup.AddValidBasis(_scenario.ExistingApplicationBasis);

            SignIn(driver, "/#/configuration/general/validcombination/basis");

            var basisPicklist = new PickList(driver).ByName(string.Empty, "basis");
            basisPicklist.OpenPickList(_scenario.ExistingApplicationBasis.Name);
            basisPicklist.DeleteRow(0);

            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().WithJs().Click();

            popups.AlertModal.Ok();

            basisPicklist.SearchFor(_scenario.ExistingApplicationBasis.Name);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(3, searchResults.Rows.Count, "Basis should get deleted");
            Assert.AreEqual(_scenario.ExistingApplicationBasis.Name, searchResults.CellText(0, 0), "Ensure the text is updated");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class BasisPicklistEditing : IntegrationTest
    {
        [SetUp]
        public void ClassInit()
        {
            _basisPicklistsDbSetup = new BasisPicklistsDbSetup();
            _scenario = _basisPicklistsDbSetup.Prepare();
        }

        BasisPicklistsDbSetup _basisPicklistsDbSetup;
        BasisPicklistsDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddBasisDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/basis");

            var basisPicklist = new PickList(driver).ByName(string.Empty, "basis");
            basisPicklist.SearchButton.Click();
            basisPicklist.AddPickListItem();

            var pageDetails = new BasisDetailPage(driver);
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Code.GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is equal");
            Assert.IsFalse(pageDetails.DefaultsTopic.Convention.Selected, "Convention checkbox exists and is unchecked");

            pageDetails.DefaultsTopic.Code.SendKeys("A");
            pageDetails.DefaultsTopic.Description.SendKeys(BasisPicklistsDbSetup.BasisToBeAdded);
            pageDetails.DefaultsTopic.Convention.WithJs().Click();
            pageDetails.SaveButton.ClickWithTimeout();

            Assert.AreEqual(BasisPicklistsDbSetup.BasisToBeAdded, basisPicklist.SearchGrid.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("A", basisPicklist.SearchGrid.CellText(0, 1), "Ensure the text is updated");
            Assert.IsTrue(basisPicklist.SearchGrid.RowIsHighlighted(0), "after saving maintenance dialog, row should be highlighted");

            basisPicklist.SearchFor(BasisPicklistsDbSetup.BasisToBeAdded);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(BasisPicklistsDbSetup.BasisToBeAdded, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("A", searchResults.CellText(0, 1), "Ensure the text is updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DiscardCancelDialogOnBasisChange(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/general/validcombination/basis");

            var basisPicklist = new PickList(driver).ByName(string.Empty, "basis");
            basisPicklist.OpenPickList(_scenario.BasisName);
            basisPicklist.AddPickListItem();

            var pageDetails = new BasisDetailPage(driver);

            pageDetails.DefaultsTopic.Code.SendKeys("A");

            pageDetails.DefaultsTopic.Convention.WithJs().Click();
            pageDetails.Discard();

            var popup = new CommonPopups(driver);
            popup.DiscardChangesModal.Cancel();
            Assert.AreEqual(pageDetails.DefaultsTopic.Code.GetAttribute("value"), "A", "Code is not lost");

            pageDetails.Discard();
            popup.DiscardChangesModal.Discard();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Name("code")));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditAndSaveBasisDetailsFromPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingBasis = _scenario.ExistingApplicationBasis;

            SignIn(driver, "/#/configuration/general/validcombination/basis");

            var basisPicklist = new PickList(driver).ByName(string.Empty, "basis");
            basisPicklist.OpenPickList(_scenario.BasisName);
            basisPicklist.EditRow(0);

            var pageDetails = new BasisDetailPage(driver);
            Assert.AreEqual(existingBasis.Code, pageDetails.DefaultsTopic.Code.GetAttribute("value"), "Ensure Code is equal");
            Assert.IsTrue(pageDetails.DefaultsTopic.Code.GetAttribute("disabled").Equals("true"), "Ensure Code is disabled");
            Assert.AreEqual(existingBasis.Name, pageDetails.DefaultsTopic.Description.GetAttribute("value"), "Ensure Name is equal");
            Assert.AreEqual(existingBasis.Convention == 1, pageDetails.DefaultsTopic.Convention.Selected);

            var editedName = existingBasis.Name + " edited";
            pageDetails.DefaultsTopic.Description.Clear();
            pageDetails.DefaultsTopic.Description.SendKeys(editedName);
            pageDetails.SaveButton.ClickWithTimeout();

            basisPicklist.SearchFor(editedName);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count, "Only one row is returned");
            Assert.AreEqual(editedName, searchResults.CellText(0, 0), "Ensure the text is updated");
        }
    }
}