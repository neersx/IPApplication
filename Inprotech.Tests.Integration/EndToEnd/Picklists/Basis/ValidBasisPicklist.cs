using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;
using System.Linq;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Basis
{
    [Category(Categories.E2E)]
    [TestFixture]
    class ValidBasisPicklist : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _basisPicklistsDbSetup = new ValidBasisDbSetup();
            _basisPicklistsDbSetup.Prepare();
        }

        ValidBasisDbSetup _basisPicklistsDbSetup;
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ValidBasisPicklistOperations(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);

            SignIn(driver, "/#/configuration/rules/workflows");

            var jurisdictionPicklist = new PickList(driver).ByName("ip-search-by-characteristics", "jurisdiction");
            jurisdictionPicklist.SendKeys(ValidBasisDbSetup.JurisdictionDescription);

            var propertyTypePicklist = new PickList(driver).ByName("ip-search-by-characteristics", "propertyType");
            propertyTypePicklist.SendKeys(ValidBasisDbSetup.ValidPropertyTypeDescription);

            var basisPicklist = new PickList(driver).ByName("ip-search-by-characteristics", "basis");
            basisPicklist.SearchButton.Click();

            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");
            var maintainBasis = new PickList(driver).ById("pk-basis");

            basisPicklist.AddPickListItem();

            var pageDetails = new ValidBasisDetailPage(driver);

            AddValidBasis(pageDetails, driver, basisPicklist, maintainBasis, maintainJurisdiction, maintainPropertyType);

            EditValidBasis(pageDetails, driver, basisPicklist, maintainBasis, maintainJurisdiction, maintainPropertyType);

            DuplicateValidCaseCategory(pageDetails, popups, driver, basisPicklist, maintainBasis, maintainJurisdiction, maintainPropertyType);

            basisPicklist.SearchFor(ValidBasisDbSetup.DuplicateValidBasis);
            basisPicklist.DeleteRow(0);

            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            driver.WaitForAngular();

            basisPicklist.SearchFor(ValidBasisDbSetup.DuplicateValidBasis);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, searchResults.Rows.Count, "Basis should get deleted");

        }

        private void AddValidBasis(ValidBasisDetailPage pageDetails, NgWebDriver driver, PickList basisPicklist, PickList maintainBasis, PickList maintainJurisdiction, PickList maintainPropertyType)
        {

            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.AreEqual(ValidBasisDbSetup.JurisdictionDescription, maintainJurisdiction.Tags.First(), "Ensure Jurisdiction Value");
            Assert.AreEqual(ValidBasisDbSetup.ValidPropertyTypeDescription, maintainPropertyType.GetText(), "Ensure Property Type Value");

            maintainBasis.EnterAndSelect(ValidBasisDbSetup.ValidBasisDescription);
            Assert.AreEqual(ValidBasisDbSetup.ValidBasisDescription, pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure Valid Description value");
            pageDetails.SaveButton.ClickWithTimeout();

            basisPicklist.SearchFor(ValidBasisDbSetup.ValidBasisDescription);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidBasisDbSetup.ValidBasisDescription, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("e2", searchResults.CellText(0, 1), "Ensure the text is updated");
        }

        private void EditValidBasis(ValidBasisDetailPage pageDetails, NgWebDriver driver, PickList basisPicklist, PickList maintainBasis, PickList maintainJurisdiction, PickList maintainPropertyType)
        {
            basisPicklist.EditRow(0);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsFalse(maintainJurisdiction.Enabled);
            Assert.IsFalse(maintainPropertyType.Enabled);
            Assert.IsFalse(maintainBasis.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();
            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys(ValidBasisDbSetup.ValidBasisEdited);
            pageDetails.SaveButton.ClickWithTimeout();
            var searchResults = new KendoGrid(driver, "picklistResults");
            basisPicklist.SearchFor(ValidBasisDbSetup.ValidBasisEdited);
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidBasisDbSetup.ValidBasisEdited, searchResults.CellText(0, 0), "Ensure valid description is updated");
        }

        private void DuplicateValidCaseCategory(ValidBasisDetailPage pageDetails, CommonPopups popups, NgWebDriver driver, PickList basisPicklist, PickList maintainBasis, PickList maintainJurisdiction, PickList maintainPropertyType)
        {
            basisPicklist.DuplicateRow(0);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.IsTrue(maintainBasis.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            Assert.AreEqual(ValidBasisDbSetup.JurisdictionDescription, maintainJurisdiction.Tags.First(), "Ensure JurisdictionValue");
            Assert.AreEqual(ValidBasisDbSetup.ValidPropertyTypeDescription, maintainPropertyType.GetText(), "Ensure Property Type value");
            Assert.AreEqual(ValidBasisDbSetup.ValidBasisEdited, pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure value");

            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();

            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys(ValidBasisDbSetup.DuplicateValidBasis);
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.True(popups.AlertModal.Modal.Displayed, "Valid Basis Already Exists");
            popups.AlertModal.Ok();

            maintainBasis.Clear();
            maintainBasis.EnterAndSelect(ValidBasisDbSetup.DuplicateValidBasis);
            pageDetails.SaveButton.ClickWithTimeout();
            basisPicklist.SearchFor(ValidBasisDbSetup.DuplicateValidBasis);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidBasisDbSetup.DuplicateValidBasis, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("e3", searchResults.CellText(0, 1), "Ensure the text is updated");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ValidBasisExPicklistOperations(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);

            SignIn(driver, "/#/configuration/rules/workflows");

            var caseTypePicklist = new PickList(driver).ByName("ip-search-by-characteristics", "caseType");
            caseTypePicklist.SendKeys(ValidBasisDbSetup.CaseTypeDescription);

            var jurisdictionPicklist = new PickList(driver).ByName("ip-search-by-characteristics", "jurisdiction");
            jurisdictionPicklist.SendKeys(ValidBasisDbSetup.JurisdictionDescription);

            var propertyTypePicklist = new PickList(driver).ByName("ip-search-by-characteristics", "propertyType");
            propertyTypePicklist.SendKeys(ValidBasisDbSetup.ValidPropertyTypeDescription);

            var caseCategoryPicklist = new PickList(driver).ByName("ip-search-by-characteristics", "caseCategory");
            caseCategoryPicklist.SendKeys(ValidBasisDbSetup.ValidCaseCategoryDescription);

            var basisPicklist = new PickList(driver).ByName("ip-search-by-characteristics", "basis");
            basisPicklist.SearchButton.Click();

            var maintainCaseType = new PickList(driver).ById("pk-case-type");
            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");
            var maintainCaseCategory = new PickList(driver).ById("pk-case-category");
            var maintainBasis = new PickList(driver).ById("pk-basis");

            basisPicklist.AddPickListItem();

            var pageDetails = new ValidBasisDetailPage(driver);

            VerifyPageFields(pageDetails, maintainCaseType, maintainJurisdiction, maintainPropertyType, maintainCaseCategory);

            maintainBasis.EnterAndSelect(ValidBasisDbSetup.ValidBasisDescription);
            Assert.AreEqual(ValidBasisDbSetup.ValidBasisDescription, pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure Valid Description value");
            pageDetails.SaveButton.ClickWithTimeout();

            basisPicklist.SearchFor(ValidBasisDbSetup.ValidBasisDescription);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidBasisDbSetup.ValidBasisDescription, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("e2", searchResults.CellText(0, 1), "Ensure the text is updated");

            EditValidBasis(searchResults, basisPicklist, driver, pageDetails, maintainCaseType, maintainJurisdiction, maintainPropertyType, maintainCaseCategory, maintainBasis);

            DuplicateValidCaseCategory(popups, searchResults, basisPicklist, driver, pageDetails, maintainCaseType, maintainJurisdiction, maintainPropertyType, maintainCaseCategory, maintainBasis);

            basisPicklist.SearchFor(ValidBasisDbSetup.DuplicateValidBasis);
            basisPicklist.DeleteRow(0);

            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            driver.WaitForAngular();

            basisPicklist.SearchFor(ValidBasisDbSetup.DuplicateValidBasis);

            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, searchResults.Rows.Count, "Basis should get deleted");
        }

        private void VerifyPageFields(ValidBasisDetailPage pageDetails, PickList maintainCaseType, PickList maintainJurisdiction, PickList maintainPropertyType, PickList maintainCaseCategory)
        {
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.AreEqual(ValidBasisDbSetup.CaseTypeDescription, maintainCaseType.GetText(), "Ensure Case Type Value");
            Assert.AreEqual(ValidBasisDbSetup.JurisdictionDescription, maintainJurisdiction.Tags.First(), "Ensure Jurisdiction Value");
            Assert.AreEqual(ValidBasisDbSetup.ValidPropertyTypeDescription, maintainPropertyType.GetText(), "Ensure Property Type Value");
            Assert.AreEqual(ValidBasisDbSetup.ValidCaseCategoryDescription, maintainCaseCategory.GetText(), "Ensure Case Category Value");
        }

        private void EditValidBasis(KendoGrid searchResults, PickList basisPicklist, NgWebDriver driver, ValidBasisDetailPage pageDetails, PickList maintainCaseType, PickList maintainJurisdiction, PickList maintainPropertyType, PickList maintainCaseCategory, PickList maintainBasis)
        {
            basisPicklist.EditRow(0);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsFalse(maintainCaseType.Enabled);
            Assert.IsFalse(maintainJurisdiction.Enabled);
            Assert.IsFalse(maintainPropertyType.Enabled);
            Assert.IsFalse(maintainCaseCategory.Enabled);
            Assert.IsFalse(maintainBasis.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();
            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys(ValidBasisDbSetup.ValidBasisEdited);
            pageDetails.SaveButton.ClickWithTimeout();
            searchResults = new KendoGrid(driver, "picklistResults");
            basisPicklist.SearchFor(ValidBasisDbSetup.ValidBasisEdited);
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidBasisDbSetup.ValidBasisEdited, searchResults.CellText(0, 0), "Ensure valid description is updated");
        }

        private void DuplicateValidCaseCategory(CommonPopups popups, KendoGrid searchResults, PickList basisPicklist, NgWebDriver driver, ValidBasisDetailPage pageDetails, PickList maintainCaseType, PickList maintainJurisdiction, PickList maintainPropertyType, PickList maintainCaseCategory, PickList maintainBasis)
        {
            basisPicklist.DuplicateRow(0);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsTrue(maintainCaseType.Enabled);
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.IsTrue(maintainCaseCategory.Enabled);
            Assert.IsTrue(maintainBasis.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            Assert.AreEqual(ValidBasisDbSetup.CaseTypeDescription, maintainCaseType.GetText(), "Ensure Case Type Value");
            Assert.AreEqual(ValidBasisDbSetup.JurisdictionDescription, maintainJurisdiction.Tags.First(), "Ensure JurisdictionValue");
            Assert.AreEqual(ValidBasisDbSetup.ValidPropertyTypeDescription, maintainPropertyType.GetText(), "Ensure Property Type value");
            Assert.AreEqual(ValidBasisDbSetup.ValidCaseCategoryDescription, maintainCaseCategory.GetText(), "Ensure Case Category value");
            Assert.AreEqual(ValidBasisDbSetup.ValidBasisEdited, pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure value");

            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();

            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys(ValidBasisDbSetup.DuplicateValidBasis);
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.True(popups.AlertModal.Modal.Displayed, "Valid Basis Already Exists");
            popups.AlertModal.Ok();

            maintainBasis.Clear();
            maintainBasis.EnterAndSelect(ValidBasisDbSetup.DuplicateValidBasis);
            pageDetails.SaveButton.ClickWithTimeout();
            basisPicklist.SearchFor(ValidBasisDbSetup.DuplicateValidBasis);

            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidBasisDbSetup.DuplicateValidBasis, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("e3", searchResults.CellText(0, 1), "Ensure the text is updated");
        }
    }
}