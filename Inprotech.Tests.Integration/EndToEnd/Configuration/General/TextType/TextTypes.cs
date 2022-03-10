using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.TextType
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TextTypes : IntegrationTest
    {

        TextTypesDbSetup _textTypesDbSetup;
        TextTypesDbSetup.ScenarioData _scenario;

        [SetUp]
        public void Setup()
        {
            _textTypesDbSetup = new TextTypesDbSetup();
            _scenario = _textTypesDbSetup.Prepare();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SearchTextTypeByCodeAndDescription(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/texttypes");

            #region search by code
            var pageDetails = new TextTypesDetailPage(driver);
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Code);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Text type code should get searched");
            #endregion

            #region search by description
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Name);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Text type description should get searched");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddTextType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingTextType = _scenario.ExistingTextType;

            SignIn(driver, "/#/configuration/general/texttypes");

            var pageDetails = new TextTypesDetailPage(driver);
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();

            #region verify page fields
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Code(driver).GetAttribute("value"), "Ensure Code is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description(driver).GetAttribute("value"), "Ensure Description is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Description(driver).GetAttribute("disabled"), "Ensure Description is enabled");
            Assert.IsTrue(pageDetails.DefaultsTopic.CasesRadioButton(driver).Selected, "Applicable for Cases radio button exists and is selected");
            Assert.IsFalse(pageDetails.DefaultsTopic.NamesRadioButton(driver).Selected, "Applicable for Names radio button exists and is not selected");
            Assert.IsNotNull(pageDetails.DefaultsTopic.EmployeeCheckbox(driver).GetAttribute("disabled"), "Ensure Staff checkbox is disabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.IndividualCheckbox(driver).GetAttribute("disabled"), "Ensure Individual checkbox is disabled");
            Assert.IsNotNull(pageDetails.DefaultsTopic.OrganisationCheckbox(driver).GetAttribute("disabled"), "Ensure Organisation checkbox is disabled");
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            #endregion

            #region Check For Unique Code And Description And Max Length
            pageDetails.DefaultsTopic.Code(driver).SendKeys(existingTextType.Id);
            pageDetails.DefaultsTopic.Description(driver).SendKeys(existingTextType.TextDescription);
            driver.WaitForAngular();
            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "textTypeCode").HasError, "Code should be unique");

            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).Clear();

            pageDetails.DefaultsTopic.Code(driver).SendKeys("***");
            Assert.IsTrue(new TextField(driver, "textTypeCode").HasError, "Code should be maximum 2 characters");

            pageDetails.DefaultsTopic.Description(driver).SendKeys("123456789012345678901234567890123456789012345678901");
            Assert.IsTrue(new TextField(driver, "description").HasError, "Description should be maximum 50 characters");
            #endregion

            #region Add Text Type
            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).Clear();

            pageDetails.DefaultsTopic.Code(driver).SendKeys("*");
            pageDetails.DefaultsTopic.Description(driver).SendKeys(TextTypesDbSetup.TextTypeToBeAdded);
           
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(TextTypesDbSetup.TextTypeToBeAdded);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("*", searchResults.CellText(0, 1), "Ensure the text type is updated");
            Assert.AreEqual(TextTypesDbSetup.TextTypeToBeAdded, searchResults.CellText(0, 2), "Ensure the text type is updated");
            #endregion

            #region Duplicate Text Type
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Code);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Text type code should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            Assert.IsNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is enabled");
            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Code(driver).SendKeys("#");
            pageDetails.DefaultsTopic.Description(driver).SendKeys(TextTypesDbSetup.TextTypeToBeDuplicate);
            driver.WaitForAngularWithTimeout();
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(TextTypesDbSetup.TextTypeToBeDuplicate);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("#", searchResults.CellText(0, 1), "Ensure the text is updated");
            Assert.AreEqual(TextTypesDbSetup.TextTypeToBeDuplicate, searchResults.CellText(0, 2), "Ensure the text is updated");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditTextType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/texttypes");

            var pageDetails = new TextTypesDetailPage(driver);

            #region Edit Text Type
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(TextTypesDbSetup.TextTypeDescription);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Record should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            Assert.IsNotNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is disabled");
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(TextTypesDbSetup.TextTypeToBeEdit);
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(TextTypesDbSetup.TextTypeToBeEdit, searchResults.CellText(0, 2), "Ensure the text is updated");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteTextType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/texttypes");

            var pageDetails = new TextTypesDetailPage(driver);
            var popups = new CommonPopups(driver);

            #region Delete Successfully
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Code);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.AreEqual(0, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Text type code should not get searched as deleted");
            #endregion

            #region Unable to complete as records in use
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("Abstract");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Text should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Text should get searched as in use");
            #endregion

            #region Partial complete as records in use
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("Abstract");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Text should get searched as in use");
            #endregion

        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ChangeTextTypeCode(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/texttypes");

            var pageDetails = new TextTypesDetailPage(driver);
            var existingTextType = _scenario.ExistingTextType;

            #region Verify Change Text Type Code is disabled for Protected Code
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys("Text-protected");
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Text type code should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            Assert.IsTrue(pageDetails.DefaultsTopic.ChangeTextTypeCode(driver).GetAttribute("class").Equals("disabled"), "Ensure Change Text Type Code is disabled");
            #endregion

            #region Verify Change Text Type Code is enabled for Unprotected Code and change code
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Code);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Text type code should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ChangeTextTypeCode(driver).ClickWithTimeout();

            pageDetails.DefaultsTopic.NewTextTypeCode(driver).SendKeys(existingTextType.Id);
            pageDetails.SaveButton.ClickWithTimeout();
            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "newTextTypeCode").HasError, "Code should be unique");
            pageDetails.DefaultsTopic.NewTextTypeCode(driver).Clear();
            pageDetails.DefaultsTopic.NewTextTypeCode(driver).SendKeys("***");
            Assert.IsTrue(new TextField(driver, "newTextTypeCode").HasError, "Code should be maximum 2 characters");
            pageDetails.DefaultsTopic.NewTextTypeCode(driver).Clear();
            pageDetails.DefaultsTopic.NewTextTypeCode(driver).SendKeys("*");
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
