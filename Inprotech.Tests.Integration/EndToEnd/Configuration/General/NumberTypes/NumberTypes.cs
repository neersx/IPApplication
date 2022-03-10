using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.NumberTypes
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "16")]
    public class NumberTypes : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _numberTypesDbSetup = new NumberTypesDbSetup();
            _scenario = _numberTypesDbSetup.Prepare();
        }

        NumberTypesDbSetup _numberTypesDbSetup;
        NumberTypesDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SearchNumberTypeByCodeAndDescription(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/numbertypes");

            #region search by code
            var pageDetails = new NumberTypesDetailPage(driver);
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Code);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Number type code should get searched");
            #endregion

            #region search by description
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Name);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Number type description should get searched");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddNumberType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingNumberType = _scenario.ExistingApplicationNumberType;

            SignIn(driver, "/#/configuration/general/numbertypes");

            var pageDetails = new NumberTypesDetailPage(driver);
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();

            #region verify page fields
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Code(driver).GetAttribute("value"), "Ensure Code is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description(driver).GetAttribute("value"), "Ensure Description is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Description(driver).GetAttribute("disabled"), "Ensure Description is enabled");
            Assert.IsFalse(pageDetails.DefaultsTopic.IssuedByIpOfficeCheckbox(driver).Selected, "Issued By Ip Office checkbox exists and is checked");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.RelatedEventPicklist(driver).GetAttribute("value"), "Ensure Related Event Picklist is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.RelatedEventPicklist(driver).GetAttribute("disabled"), "Ensure Related Event Picklist is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.DataItemPicklist(driver).GetAttribute("value"), "Ensure Data Item Picklist is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.DataItemPicklist(driver).GetAttribute("disabled"), "Ensure Data Item Picklist is enabled");
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.Throws<NoSuchElementException>(() => pageDetails.DefaultsTopic.NavigationBar(driver), "Ensure Navigation Bar is not visible");
            #endregion

            #region Check For Unique Code And Description And Max Length
            pageDetails.DefaultsTopic.Code(driver).SendKeys(existingNumberType.NumberTypeCode);
            pageDetails.DefaultsTopic.Description(driver).SendKeys(existingNumberType.Name);
            driver.WaitForAngular();
            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "numberTypeCode").HasError, "Code should be unique");

            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).Clear();

            pageDetails.DefaultsTopic.Code(driver).SendKeys("****");
            Assert.IsTrue(new TextField(driver, "numberTypeCode").HasError, "Code should be maximum 3 characters");

            pageDetails.DefaultsTopic.Description(driver).SendKeys("123456789012345678901234567890123456789012345678901");
            Assert.IsTrue(new TextField(driver, "name").HasError, "Description should be maximum 30 characters");
            #endregion

            #region Add Number Type
            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).Clear();

            pageDetails.DefaultsTopic.Code(driver).SendKeys("*");
            pageDetails.DefaultsTopic.Description(driver).SendKeys(NumberTypesDbSetup.NumberTypeToBeAdded);

            var relatedEventPicklist = new PickList(driver).ByName(string.Empty, "relatedEvent");
            relatedEventPicklist.EnterAndSelect("Application Filing Date");
            driver.WaitForAngularWithTimeout();

            var dataItemPicklist = new PickList(driver).ByName(string.Empty, "dataItem");
            dataItemPicklist.EnterAndSelect("ACCEPTANCE_NO");
            driver.WaitForAngularWithTimeout();

            pageDetails.SaveButton.ClickWithTimeout();

            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.SetNumberTypePriorityButtonDown(driver).GetAttribute("disabled"), "Ensure Down Button is disabled");
            Assert.IsNull(pageDetails.DefaultsTopic.SetNumberTypePriorityButtonUp(driver).GetAttribute("disabled"), "Ensure Up Button is enabled");
            var prioritySearchResults = new KendoGrid(driver, "validNumberTypesResults");
            var secondRowCodeValue = prioritySearchResults.CellText(1, 0);
            prioritySearchResults.Cell(1, 0).Click();
            pageDetails.DefaultsTopic.SetNumberTypePriorityButtonUp(driver).Click();
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.AreEqual(secondRowCodeValue, prioritySearchResults.CellText(0, 0), "Ensure priority order updated");
            pageDetails.DiscardButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NumberTypesDbSetup.NumberTypeToBeAdded);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("*", searchResults.CellText(0, 1), "Ensure the text is updated");
            Assert.AreEqual(NumberTypesDbSetup.NumberTypeToBeAdded, searchResults.CellText(0, 2), "Ensure the text is updated");
            Assert.AreEqual("Application Filing Date", searchResults.CellText(0, 4), "Ensure the text is updated");
            #endregion

            #region Duplicate Number Type
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Code);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Number type code should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            Assert.IsNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is enabled");
            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Code(driver).SendKeys("#");
            pageDetails.DefaultsTopic.Description(driver).SendKeys(NumberTypesDbSetup.NumberTypeToBeDuplicate);
            dataItemPicklist.EnterAndSelect("ACCEPTANCE_NO");
            driver.WaitForAngularWithTimeout();
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NumberTypesDbSetup.NumberTypeToBeDuplicate);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("#", searchResults.CellText(0, 1), "Ensure the text is updated");
            Assert.AreEqual(NumberTypesDbSetup.NumberTypeToBeDuplicate, searchResults.CellText(0, 2), "Ensure the text is updated");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteNumberType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/numbertypes");

            var pageDetails = new NumberTypesDetailPage(driver);
            var popups = new CommonPopups(driver);

            #region Delete Successfully
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Name);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.AreEqual(0, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Number type code should not get searched as deleted");
            #endregion

            #region Unable to complete as records in use
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("CPA Format Application No.");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Result should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Result should get searched as in use");
            #endregion

            #region Partial complete as records in use
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("Registration No.");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Result should get searched as in use");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditNumberType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/numbertypes");

            var pageDetails = new NumberTypesDetailPage(driver);

            #region Edit Number Type
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NumberTypesDbSetup.NumberTypeDescription);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Record should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            Assert.IsNotNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is disabled");
            Assert.IsTrue(pageDetails.DefaultsTopic.NavigationBar(driver).Displayed, "Ensure Navigation Bar is visible");
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(NumberTypesDbSetup.NumberTypeToBeEdit);
            var dataItemPicklist = new PickList(driver).ByName(string.Empty, "dataItem");
            dataItemPicklist.EnterAndSelect("ACCEPTANCE_NO");
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(NumberTypesDbSetup.NumberTypeToBeEdit, searchResults.CellText(0, 2), "Ensure the text is updated");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SetNumberTypePriority(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/numbertypes");

            var pageDetails = new NumberTypesDetailPage(driver);

            #region Set Number Type Priority by button up
            pageDetails.DefaultsTopic.SetNumberTypePriorityLink(driver).Click();
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.SetNumberTypePriorityButtonDown(driver).GetAttribute("disabled"), "Ensure Down Button is disabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.SetNumberTypePriorityButtonUp(driver).GetAttribute("disabled"), "Ensure Up Button is disabled");
            var searchResults = new KendoGrid(driver, "validNumberTypesResults");
            var secondRowCodeValue = searchResults.CellText(1, 0);
            searchResults.Cell(1, 0).Click();
            pageDetails.DefaultsTopic.SetNumberTypePriorityButtonUp(driver).Click();
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SetNumberTypePriorityLink(driver).Click();
            Assert.AreEqual(secondRowCodeValue, searchResults.CellText(0, 0), "Ensure priority order updated");
            pageDetails.DiscardButton.ClickWithTimeout();
            #endregion

            #region Set Number Type Priority by button down
            pageDetails.DefaultsTopic.SetNumberTypePriorityLink(driver).Click();
            var firstRowCodeValue = searchResults.CellText(0, 0);
            searchResults.Cell(0, 0).Click();
            pageDetails.DefaultsTopic.SetNumberTypePriorityButtonDown(driver).Click();
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SetNumberTypePriorityLink(driver).Click();
            Assert.AreEqual(firstRowCodeValue, searchResults.CellText(1, 0), "Ensure priority order updated");
            pageDetails.DiscardButton.ClickWithTimeout();
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ChangeNumberTypeCode(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/numbertypes");

            var pageDetails = new NumberTypesDetailPage(driver);
            var existingNumberType = _scenario.ExistingApplicationNumberType;

            #region Verify Change Number Type Code is disabled for Protected Code
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("e2e - protected");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Number type code should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            Assert.IsTrue(pageDetails.DefaultsTopic.ChangeNumberTypeCode(driver).GetAttribute("class").Equals("disabled"), "Ensure Change Number Type Code is disabled");
            #endregion

            #region Verify Change Number Type Code is enabled for Unprotected Code and change code
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Code);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Number type code should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ChangeNumberTypeCode(driver).ClickWithTimeout();

            pageDetails.DefaultsTopic.NewNumberTypeCode(driver).SendKeys(existingNumberType.NumberTypeCode);
            pageDetails.SaveButton.ClickWithTimeout();
            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "newNumberTypeCode").HasError, "Code should be unique");
            pageDetails.DefaultsTopic.NewNumberTypeCode(driver).Clear();
            pageDetails.DefaultsTopic.NewNumberTypeCode(driver).SendKeys("****");
            Assert.IsTrue(new TextField(driver, "newNumberTypeCode").HasError, "Code should be maximum 3 characters");
            pageDetails.DefaultsTopic.NewNumberTypeCode(driver).Clear();
            pageDetails.DefaultsTopic.NewNumberTypeCode(driver).SendKeys("*");
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("*");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("*", searchResults.CellText(0, 1), "Ensure the text is updated");
            #endregion
        }
    }
}
