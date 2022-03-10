using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.NameRelation
{
    class NameRelation : IntegrationTest
    {
        NameRelationDbSetup _nameRelationDbSetup;
        NameRelationDbSetup.ScenarioData _scenario;

        [SetUp]
        public void Setup()
        {
            _nameRelationDbSetup = new NameRelationDbSetup();
            _scenario = _nameRelationDbSetup.Prepare();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainNameRelationship(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/names/namerelations");

            var pageDetails = new NameRelationDetailPage(driver);
            var model = _scenario.NameRelationsModel;
            var page = pageDetails.DefaultsTopic;

            #region Add NameRelation
            page.AddButton(driver).ClickWithTimeout();
            page.RelationshipCode(driver).SendKeys(model.RelationshipCode);
            page.RelationshipDescription(driver).SendKeys(model.RelationshipDescription);
            page.ReverseDescription(driver).SendKeys(model.ReverseDescription);
            page.ChkEmployee.Click();
            Assert.True(page.ChkEmployee.IsChecked, "Ensure checkbox is checked");
            page.ChkIndividual.Click();
            Assert.True(page.ChkIndividual.IsChecked, "Ensure checkbox is checked");
            page.ChkOrganisation.Click();
            Assert.True(page.ChkOrganisation.IsChecked, "Ensure checkbox is checked");
            page.ChkCrmOnly.Click();
            Assert.True(page.ChkCrmOnly.IsChecked, "Ensure checkbox is checked");
            page.RdoDenyAccess.Click();
            Assert.True(page.RdoDenyAccess.IsChecked, "Ensure radio button is selected");
            pageDetails.SaveButton.ClickWithTimeout();
            page.SearchTextBox(driver).Clear();
            page.SearchTextBox(driver).SendKeys(model.RelationshipCode);
            page.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, page.GetSearchResultCount(driver), "Name relationship code should get searched");
            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(model.RelationshipCode, searchResults.CellText(0, 1), "Ensure the text is same");
            Assert.AreEqual(model.RelationshipDescription, searchResults.CellText(0, 2), "Ensure the text is same");
            Assert.AreEqual(model.ReverseDescription, searchResults.CellText(0, 3), "Ensure the text is same");
            Assert.AreEqual(model.EthicalWallValue, searchResults.CellText(0, 8), "Ensure the text is same");
            #endregion

            #region Edit NameRelation
            const string editedText = "Edited";
            const string editedEthicalWallOption = "Allow Access";
            page.ClickOnBulkActionMenu(driver);
            page.ClickOnSelectAll(driver);
            page.ClickOnEdit(driver);
            Assert.IsNotNull(page.RelationshipCode(driver).GetAttribute("disabled"), "Ensure RelationshipCode is disabled");
            Assert.IsTrue(page.NavigationBar(driver).Displayed, "Ensure Navigation Bar is visible");
            page.RelationshipDescription(driver).Clear();
            page.RelationshipDescription(driver).SendKeys(editedText);
            page.ReverseDescription(driver).Clear();
            page.ReverseDescription(driver).SendKeys(editedText);
            page.ChkEmployee.Click();
            Assert.False(page.ChkEmployee.IsChecked, "Ensure checkbox is unchecked");
            page.RdoAllowAccess.Click();
            Assert.True(page.RdoAllowAccess.IsChecked, "Ensure radio button is checked");
            page.ChkCrmOnly.Click();
            Assert.False(page.ChkCrmOnly.IsChecked, "Ensure checkbox is unchecked");
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            page.SearchTextBox(driver).Clear();
            page.SearchTextBox(driver).SendKeys(model.RelationshipCode);
            page.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, page.GetSearchResultCount(driver), "Name relationship code should get searched");
            searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(model.RelationshipCode, searchResults.CellText(0, 1), "Ensure the text is same");
            Assert.AreEqual(editedText, searchResults.CellText(0, 2), "Ensure the text is same");
            Assert.AreEqual(editedText, searchResults.CellText(0, 3), "Ensure the text is same");
            Assert.AreEqual(editedEthicalWallOption, searchResults.CellText(0, 8), "Ensure the text is same");
            #endregion
            
            #region Duplicate Name Relation
            const string duplicateText = "DUP";
            page.ClickOnBulkActionMenu(driver);
            page.ClickOnSelectAll(driver);
            page.ClickOnDuplicate(driver);
            Assert.IsNull(page.RelationshipCode(driver).GetAttribute("disabled"), "Ensure relationship code is enabled");
            page.RelationshipCode(driver).Clear();
            page.RelationshipCode(driver).SendKeys(duplicateText);
            page.RelationshipDescription(driver).Clear();
            page.RelationshipDescription(driver).SendKeys(duplicateText);
            page.ReverseDescription(driver).Clear();
            page.ReverseDescription(driver).SendKeys(duplicateText);
            pageDetails.SaveButton.ClickWithTimeout();
            page.SearchTextBox(driver).Clear();
            page.SearchTextBox(driver).SendKeys(duplicateText);
            page.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, page.GetSearchResultCount(driver), "Name relationship code should get searched");
            Assert.AreEqual(duplicateText, searchResults.CellText(0, 1), "Ensure the text is same");
            Assert.AreEqual(duplicateText, searchResults.CellText(0, 2), "Ensure the text is same");
            Assert.AreEqual(duplicateText, searchResults.CellText(0, 3), "Ensure the text is same");
            Assert.AreEqual(editedEthicalWallOption, searchResults.CellText(0, 8), "Ensure the text is same");
            #endregion

            #region Delete Name Relationship Successfully
            
            page.ClickOnBulkActionMenu(driver);
            page.ClickOnSelectAll(driver);
            page.ClickOnDelete(driver);
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.AreEqual(0, page.GetSearchResultCount(driver), "Name relationship should not get searched as deleted");

            #endregion
            
            #region Unable to Delete Name Relationship as in use
            page.SearchTextBox(driver).Clear();
            page.SearchTextBox(driver).SendKeys(_scenario.UsedNameRelation.RelationshipCode);
            page.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, page.GetSearchResultCount(driver), "Name relation should get searched");
            Assert.AreEqual(_scenario.UsedNameRelation.RelationshipCode, searchResults.CellText(0, 1), "Ensure the text is same");
            page.ClickOnBulkActionMenu(driver);
            page.ClickOnSelectAll(driver);
            page.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.AreEqual(1, page.GetSearchResultCount(driver), "Result should get searched as in use");
            #endregion
        }
    }
}
