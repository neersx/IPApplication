using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Names.NameAliasType
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class NameAliasType : IntegrationTest
    {
        NameAliasTypeDbSetup _nameAliasTypesDbSetup;
        NameAliasTypeDbSetup.ScenarioData _scenario;

        [SetUp]
        public void Setup()
        {
            _nameAliasTypesDbSetup = new NameAliasTypeDbSetup();
            _scenario = _nameAliasTypesDbSetup.Prepare();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void NameAliasTypeE2ETest(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/names/namealiastype");
            var existingTextType = _scenario.ExistingNameAliasType;

            #region search by code
            var pageDetails = new NameAliasTypeDetailPage(driver);
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Code);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Name alias type code should get searched");
            #endregion

            #region search by description
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Description);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Name alias description should get searched");
            #endregion

            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();

            #region verify page fields
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Code(driver).GetAttribute("value"), "Ensure Code is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is enabled");
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description(driver).GetAttribute("value"), "Ensure Description is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Description(driver).GetAttribute("disabled"), "Ensure Description is enabled");
            Assert.IsNull(pageDetails.DefaultsTopic.UniqueCheckbox(driver).GetAttribute("disabled"), "Ensure unique checkbox is enabled");
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.Throws<NoSuchElementException>(() => pageDetails.DefaultsTopic.NavigationBar(driver), "Ensure Navigation Bar is not visible");
            #endregion

            #region Check For Unique Code, Description And Max Length
            pageDetails.DefaultsTopic.Code(driver).SendKeys(existingTextType.Code);
            pageDetails.DefaultsTopic.Description(driver).SendKeys(existingTextType.Description);
            driver.WaitForAngular();
            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "type").HasError, "Code should be unique");

            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).Clear();

            pageDetails.DefaultsTopic.Code(driver).SendKeys("***");
            Assert.IsTrue(new TextField(driver, "type").HasError, "Code should be maximum 2 characters");

            pageDetails.DefaultsTopic.Description(driver).SendKeys("123456789012345678901234567890123456789012345678901");
            Assert.IsTrue(new TextField(driver, "description").HasError, "Description should be maximum 30 characters");
            #endregion

            #region Add Name Alias Type
            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).Clear();

            pageDetails.DefaultsTopic.Code(driver).SendKeys("*");
            pageDetails.DefaultsTopic.Description(driver).SendKeys(NameAliasTypeDbSetup.NameAliasTypeToBeAdded);
            pageDetails.DefaultsTopic.UniqueCheckbox(driver).WithJs().Click();

            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NameAliasTypeDbSetup.NameAliasTypeToBeAdded);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("*", searchResults.CellText(0, 1), "Ensure the name alias type is updated");
            Assert.AreEqual(NameAliasTypeDbSetup.NameAliasTypeToBeAdded, searchResults.CellText(0, 2), "Ensure the name alias type description is updated");
            #endregion

            #region Duplicate Name Alias Type
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.Code);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Name alias type code should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            driver.WaitForAngularWithTimeout();
            Assert.IsNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is enabled");
            pageDetails.DefaultsTopic.Code(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Code(driver).SendKeys("#");
            pageDetails.DefaultsTopic.Description(driver).SendKeys(NameAliasTypeDbSetup.NameAliasTypeToBeDuplicate);
            driver.WaitForAngularWithTimeout();
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NameAliasTypeDbSetup.NameAliasTypeToBeDuplicate);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("#", searchResults.CellText(0, 1), "Ensure the text is updated");
            Assert.AreEqual(NameAliasTypeDbSetup.NameAliasTypeToBeDuplicate, searchResults.CellText(0, 2), "Ensure the text is updated");
            #endregion

            #region Edit Name Alias Type
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            Assert.IsNotNull(pageDetails.DefaultsTopic.Code(driver).GetAttribute("disabled"), "Ensure Code is disabled");
            Assert.IsTrue(pageDetails.DefaultsTopic.NavigationBar(driver).Displayed, "Ensure Navigation Bar is visible");
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(NameAliasTypeDbSetup.NameAliasTypeToBeEdit);
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchTextBox(driver).Clear();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(NameAliasTypeDbSetup.NameAliasTypeToBeEdit);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(NameAliasTypeDbSetup.NameAliasTypeToBeEdit, searchResults.CellText(0, 2), "Ensure the text is updated");
            #endregion

            #region Delete Successfully
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.AreEqual(0, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Name alias type code should not get searched as deleted");
            #endregion

            #region Unable to complete as records in use
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.ExistingNameAliasType.Code);
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
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            popups.AlertModal.Ok();
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchTextBox(driver).SendKeys(_scenario.ExistingNameAliasType.Code);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Text should get searched as in use");
            #endregion
        }
    }
}
