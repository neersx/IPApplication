using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.NameRestrictions
{
    [Category(Categories.E2E)]
    [TestFixture]
    class NameRestrictions : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _nameRestrictionsDbSetup = new NameRestrictionsDbSetup();
            _scenario = _nameRestrictionsDbSetup.Prepare();
        }

        NameRestrictionsDbSetup _nameRestrictionsDbSetup;
        NameRestrictionsDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SearchNameRestrictionByDescription(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/namerestrictions");

            var pageDetails = new NameRestrictionsDetailPage(driver);
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NameRestrictionsDbSetup.NameRestrictionDescription);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Name Restriction description should get searched");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddNameRestriction(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var actionToBeTakenDropDown = new DropDown(driver).ByName("action");
            var searchResults = new KendoGrid(driver, "searchResults");

            SignIn(driver, "/#/configuration/general/namerestrictions");

            var pageDetails = new NameRestrictionsDetailPage(driver);

            DuplicateNameRestriction(pageDetails, driver, actionToBeTakenDropDown, searchResults);

            VerifyPageFields(pageDetails, driver);

            CheckUniqueNameDescAndPasswordMaxLength(pageDetails, driver, actionToBeTakenDropDown, searchResults);

            AddNameRestriction(pageDetails, driver, actionToBeTakenDropDown, searchResults);

        }

        private void DuplicateNameRestriction(NameRestrictionsDetailPage pageDetails, NgWebDriver driver, DropDown actionToBeTakenDropDown, KendoGrid searchResults)
        {
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NameRestrictionsDbSetup.NameRestrictionDescription);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Name Restriction code should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(NameRestrictionsDbSetup.NameRestrictionToBeDuplicate);
            actionToBeTakenDropDown.Text = "Display error";
            driver.WaitForAngularWithTimeout();
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NameRestrictionsDbSetup.NameRestrictionToBeDuplicate);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(NameRestrictionsDbSetup.NameRestrictionToBeDuplicate, searchResults.CellText(0, 1), "Ensure the text is updated");
            Assert.AreEqual("Display error", searchResults.CellText(0, 2), "Ensure the text is updated");
        }
        private void VerifyPageFields(NameRestrictionsDetailPage pageDetails, NgWebDriver driver)
        {
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description(driver).GetAttribute("value"), "Ensure Description is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Description(driver).GetAttribute("disabled"), "Ensure Description is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.ActionsToBeTakenDropDown(driver).GetAttribute("value"), "Ensure Actions To Be Taken DropDown is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.ActionsToBeTakenDropDown(driver).GetAttribute("disabled"), "Ensure Actions To Be Taken DropDown is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Password(driver).GetAttribute("value"), "Ensure Password is equal");
            Assert.IsNotNull(pageDetails.DefaultsTopic.Password(driver).GetAttribute("disabled"), "Ensure Description is disabled");
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.Throws<NoSuchElementException>(() => pageDetails.DefaultsTopic.NavigationBar(driver), "Ensure Navigation Bar is not visible");
        }

        private void CheckUniqueNameDescAndPasswordMaxLength(NameRestrictionsDetailPage pageDetails, NgWebDriver driver, DropDown actionToBeTakenDropDown, KendoGrid searchResults)
        {
            pageDetails.DefaultsTopic.Description(driver).SendKeys(NameRestrictionsDbSetup.NameRestrictionDescription);
            actionToBeTakenDropDown.Text = "Display warning dialog & prompt for password";
            pageDetails.DefaultsTopic.Password(driver).SendKeys("1234");
            driver.WaitForAngularWithTimeout();
            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "description").HasError, "Description should be unique");

            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys("123456789012345678901234567890123456789012345678901123456789012345678901123456789012345678901");
            Assert.IsTrue(new TextField(driver, "description").HasError, "Description should be maximum 50 characters");
            pageDetails.DefaultsTopic.Password(driver).SendKeys("123456789012345678901");
            Assert.IsTrue(new TextField(driver, "password").HasError, "Code should be maximum 10 characters");
        }

        private void AddNameRestriction(NameRestrictionsDetailPage pageDetails, NgWebDriver driver, DropDown actionToBeTakenDropDown, KendoGrid searchResults)
        {
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(NameRestrictionsDbSetup.NameRestrictionToBeAdded);
            pageDetails.DefaultsTopic.Password(driver).Clear();
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.IsTrue(new TextField(driver, "password").HasError, "Required field");
            pageDetails.DefaultsTopic.Password(driver).SendKeys("12345");
            pageDetails.SaveButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NameRestrictionsDbSetup.NameRestrictionToBeAdded);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(NameRestrictionsDbSetup.NameRestrictionToBeAdded, searchResults.CellText(0, 1), "Ensure the text is updated");
            Assert.AreEqual("Display warning dialog & prompt for password", searchResults.CellText(0, 2), "Ensure the text is updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditNameRestriction(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/namerestrictions");

            var pageDetails = new NameRestrictionsDetailPage(driver);

            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NameRestrictionsDbSetup.NameRestrictionDescription);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Record should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            Assert.IsNotNull(pageDetails.DefaultsTopic.Password(driver).GetAttribute("disabled"), "Ensure Password is disabled");
            Assert.IsTrue(pageDetails.DefaultsTopic.NavigationBar(driver).Displayed, "Ensure Navigation Bar is visible");
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(NameRestrictionsDbSetup.NameRestrictionToBeEdit);
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(NameRestrictionsDbSetup.NameRestrictionToBeEdit, searchResults.CellText(0, 1), "Ensure the text is updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteNameRestriction(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/namerestrictions");

            var pageDetails = new NameRestrictionsDetailPage(driver);
            var popups = new CommonPopups(driver);

            DeleteSuccessfully(pageDetails, driver, popups);

            UnableToCompleteRecordInUse(pageDetails, driver, popups);

            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("Absolutely");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Result should get searched as in use");
        }

        private void DeleteSuccessfully(NameRestrictionsDetailPage pageDetails, NgWebDriver driver, CommonPopups popups)
        {
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NameRestrictionsDbSetup.NameRestrictionDescription);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.AreEqual(0, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Name Restriction should not get searched as deleted");
        }

        private void UnableToCompleteRecordInUse(NameRestrictionsDetailPage pageDetails, NgWebDriver driver, CommonPopups popups)
        {
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("Absolutely no work");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Result should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Result should get searched as in use");
        }
    }
}
