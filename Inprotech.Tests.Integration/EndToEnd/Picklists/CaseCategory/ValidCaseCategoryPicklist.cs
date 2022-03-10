using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;
using System.Linq;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseCategory
{
    [Category(Categories.E2E)]
    [TestFixture]
    class ValidCaseCategoryPicklist : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _caseCategoryPicklistsDbSetup = new ValidCaseCategoryDbSetup();
            _caseCategoryPicklistsDbSetup.Prepare();
        }

        ValidCaseCategoryDbSetup _caseCategoryPicklistsDbSetup;
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ValidCaseCategoryPicklistOperations(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);

            SignIn(driver, "/#/configuration/rules/workflows");

            var caseTypePicklist = new PickList(driver).ByName("ip-search-by-characteristics", "caseType");
            caseTypePicklist.SendKeys(ValidCaseCategoryDbSetup.CaseTypeDescription);

            var jurisdictionPicklist = new PickList(driver).ByName("ip-search-by-characteristics", "jurisdiction");
            jurisdictionPicklist.SendKeys(ValidCaseCategoryDbSetup.JurisdictionDescription);

            var propertyTypePicklist = new PickList(driver).ByName("ip-search-by-characteristics", "propertyType");
            propertyTypePicklist.SendKeys(ValidCaseCategoryDbSetup.ValidPropertyTypeDescription);

            var caseCategoryPicklist = new PickList(driver).ByName("ip-search-by-characteristics", "caseCategory");
            caseCategoryPicklist.SearchButton.Click();

            var maintainCaseType= new PickList(driver).ById("pk-case-type");
            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");
            var maintainCaseCategory = new PickList(driver).ById("pk-case-category");

            #region Add Valid CaseCategory
            caseCategoryPicklist.AddPickListItem();

            var pageDetails = new ValidCaseCategoryDetailPage(driver);

            #region verify page fields
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.AreEqual(ValidCaseCategoryDbSetup.CaseTypeDescription, maintainCaseType.GetText(), "Ensure Case Type Value");
            Assert.AreEqual(ValidCaseCategoryDbSetup.JurisdictionDescription, maintainJurisdiction.Tags.First(), "Ensure Jurisdiction Value");
            Assert.AreEqual(ValidCaseCategoryDbSetup.ValidPropertyTypeDescription, maintainPropertyType.GetText(), "Ensure Property Type Value");
            #endregion

            maintainCaseCategory.EnterAndSelect(ValidCaseCategoryDbSetup.ValidCaseCategoryDescription);
            Assert.AreEqual(ValidCaseCategoryDbSetup.ValidCaseCategoryDescription, pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure Valid Description value");
            pageDetails.SaveButton.ClickWithTimeout();

            caseCategoryPicklist.SearchFor(ValidCaseCategoryDbSetup.ValidCaseCategoryDescription);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidCaseCategoryDbSetup.ValidCaseCategoryDescription, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("e2", searchResults.CellText(0, 1), "Ensure the text is updated");
            #endregion

            #region Edit Valid Case Category
            propertyTypePicklist.EditRow(0);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsFalse(maintainCaseType.Enabled);
            Assert.IsFalse(maintainJurisdiction.Enabled);
            Assert.IsFalse(maintainPropertyType.Enabled);
            Assert.IsFalse(maintainCaseCategory.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();
            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys(ValidCaseCategoryDbSetup.ValidCaseCategoryeEdited);
            pageDetails.SaveButton.ClickWithTimeout();
            searchResults = new KendoGrid(driver, "picklistResults");
            propertyTypePicklist.SearchFor(ValidCaseCategoryDbSetup.ValidCaseCategoryeEdited);
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidCaseCategoryDbSetup.ValidCaseCategoryeEdited, searchResults.CellText(0, 0), "Ensure valid description is updated");
            #endregion

            #region Duplicate Valid Case Category
            propertyTypePicklist.DuplicateRow(0);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsTrue(maintainCaseType.Enabled);
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.IsTrue(maintainCaseCategory.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            Assert.AreEqual(ValidCaseCategoryDbSetup.CaseTypeDescription, maintainCaseType.GetText(), "Ensure Case Type Value");
            Assert.AreEqual(ValidCaseCategoryDbSetup.JurisdictionDescription, maintainJurisdiction.Tags.First(), "Ensure JurisdictionValue");
            Assert.AreEqual(ValidCaseCategoryDbSetup.ValidPropertyTypeDescription, maintainPropertyType.GetText(), "Ensure Property Type value");
            Assert.AreEqual(ValidCaseCategoryDbSetup.ValidCaseCategoryDescription, maintainCaseCategory.GetText(), "Ensure Case Category value");
            Assert.AreEqual(ValidCaseCategoryDbSetup.ValidCaseCategoryeEdited, pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure value");

            #region Error On duplicate Case Category for same combination
            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();

            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys(ValidCaseCategoryDbSetup.DuplicateValidCaseCategory);
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.True(popups.AlertModal.Modal.Displayed, "Valid Case Category Already Exists");
            popups.AlertModal.Ok();
            #endregion

            maintainCaseCategory.Clear();
            maintainCaseCategory.EnterAndSelect(ValidCaseCategoryDbSetup.DuplicateValidCaseCategory);
            pageDetails.SaveButton.ClickWithTimeout();
            propertyTypePicklist.SearchFor(ValidCaseCategoryDbSetup.DuplicateValidCaseCategory);

            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidCaseCategoryDbSetup.DuplicateValidCaseCategory, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("e3", searchResults.CellText(0, 1), "Ensure the text is updated");
            #endregion

            #region Delete Valid Case Category
            caseCategoryPicklist.SearchFor(ValidCaseCategoryDbSetup.DuplicateValidCaseCategory);
            caseCategoryPicklist.DeleteRow(0);

            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            driver.WaitForAngular();

            caseCategoryPicklist.SearchFor(ValidCaseCategoryDbSetup.DuplicateValidCaseCategory);

            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, searchResults.Rows.Count, "Case Category should get deleted");
            #endregion
        }
    }
}