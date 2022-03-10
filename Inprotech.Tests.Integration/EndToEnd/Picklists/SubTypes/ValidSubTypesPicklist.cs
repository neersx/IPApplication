using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.SubTypes
{
    
    [Category(Categories.E2E)]
    [TestFixture]
    class ValidSubTypesPicklist : IntegrationTest
    {
        ValidSubTypesPicklistDbSetup _subTypePicklistsDbSetup;
        [SetUp]
        public void Setup()
        {
            _subTypePicklistsDbSetup = new ValidSubTypesPicklistDbSetup();
            _subTypePicklistsDbSetup.Prepare();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ValidSubTypePicklistOperations(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);

            SignIn(driver, "/#/configuration/rules/workflows");

            var caseTypeTypePicklist = new PickList(driver).ByName("ip-search-by-characteristics", "caseType");
            var jurisdictionPicklist = new PickList(driver).ByName("ip-search-by-characteristics", "jurisdiction");
            var propertyTypePicklist = new PickList(driver).ByName("ip-search-by-characteristics", "propertyType");
            var caseCategoryPicklist = new PickList(driver).ByName("ip-search-by-characteristics", "caseCategory");

            caseTypeTypePicklist.SendKeys(ValidSubTypesPicklistDbSetup.CaseTypeDescription);
            jurisdictionPicklist.SendKeys(ValidSubTypesPicklistDbSetup.JurisdictionDescription);
            caseCategoryPicklist.SendKeys(ValidSubTypesPicklistDbSetup.ValidCaseCategoryDescription);
            propertyTypePicklist.SendKeys(ValidSubTypesPicklistDbSetup.ValidPropertyTypeDescription);
            
            var subTypesPicklist = new PickList(driver).ByName("ip-search-by-characteristics", "subType");
            subTypesPicklist.SearchButton.ClickWithTimeout();

            var maintainCaseType = new PickList(driver).ById("pk-case-type");
            var maintainCaseCategory = new PickList(driver).ById("pk-case-category");
            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");
            var maintainSubTypes = new PickList(driver).ById("pk-sub-type");

            #region Add Valid SubType
            subTypesPicklist.AddPickListItem();

            var pageDetails = new ValidSubTypesDetailPage(driver);

            #region verify page fields
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.AreEqual(ValidSubTypesPicklistDbSetup.JurisdictionDescription, maintainJurisdiction.Tags.First(), "Ensure Jurisdiction Value");
            Assert.AreEqual(ValidSubTypesPicklistDbSetup.ValidPropertyTypeDescription, maintainPropertyType.GetText(), "Ensure Property Type Value");
            Assert.AreEqual(ValidSubTypesPicklistDbSetup.CaseTypeDescription, maintainCaseType.GetText(), "Ensure Case Type Value");
            Assert.AreEqual(ValidSubTypesPicklistDbSetup.ValidCaseCategoryDescription, maintainCaseCategory.GetText(), "Ensure Case Category Value");
            #endregion

            maintainSubTypes.EnterAndSelect(ValidSubTypesPicklistDbSetup.ValidSubTypesDescription);
            Assert.AreEqual(ValidSubTypesPicklistDbSetup.ValidSubTypesDescription, pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure Valid Description value");
            pageDetails.SaveButton.ClickWithTimeout();

            subTypesPicklist.SearchFor(ValidSubTypesPicklistDbSetup.ValidSubTypesDescription);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidSubTypesPicklistDbSetup.ValidSubTypesDescription, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("e2", searchResults.CellText(0, 1), "Ensure the text is updated");
            #endregion

            #region Edit Valid SubType
            subTypesPicklist.EditRow(0);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsFalse(maintainJurisdiction.Enabled);
            Assert.IsFalse(maintainPropertyType.Enabled);
            Assert.IsFalse(maintainSubTypes.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();
            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys(ValidSubTypesPicklistDbSetup.ValidSubTypesEdited);
            pageDetails.SaveButton.ClickWithTimeout();
            searchResults = new KendoGrid(driver, "picklistResults");
            subTypesPicklist.SearchFor(ValidSubTypesPicklistDbSetup.ValidSubTypesEdited);
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidSubTypesPicklistDbSetup.ValidSubTypesEdited, searchResults.CellText(0, 0), "Ensure valid description is updated");
            #endregion

            #region Duplicate Valid Case Category
            subTypesPicklist.DuplicateRow(0);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.IsTrue(maintainSubTypes.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            Assert.AreEqual(ValidSubTypesPicklistDbSetup.JurisdictionDescription, maintainJurisdiction.Tags.First(), "Ensure JurisdictionValue");
            Assert.AreEqual(ValidSubTypesPicklistDbSetup.ValidPropertyTypeDescription, maintainPropertyType.GetText(), "Ensure Property Type value");
            Assert.AreEqual(ValidSubTypesPicklistDbSetup.ValidSubTypesEdited, pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure value");

            #region Error On duplicate SubType for same combination
            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();

            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys(ValidSubTypesPicklistDbSetup.DuplicateValidSubTypes);
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.True(popups.AlertModal.Modal.Displayed, "Valid SubType Already Exists");
            popups.AlertModal.Ok();
            #endregion

            maintainSubTypes.Clear();
            maintainSubTypes.EnterAndSelect(ValidSubTypesPicklistDbSetup.DuplicateValidSubTypes);
            pageDetails.SaveButton.ClickWithTimeout();
            subTypesPicklist.SearchFor(ValidSubTypesPicklistDbSetup.DuplicateValidSubTypes);

            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidSubTypesPicklistDbSetup.DuplicateValidSubTypes, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("e3", searchResults.CellText(0, 1), "Ensure the text is updated");
            #endregion

            #region Delete Valid SubType
            subTypesPicklist.SearchFor(ValidSubTypesPicklistDbSetup.DuplicateValidSubTypes);
            subTypesPicklist.DeleteRow(0);

            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            driver.WaitForAngular();

            subTypesPicklist.SearchFor(ValidSubTypesPicklistDbSetup.DuplicateValidSubTypes);

            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, searchResults.Rows.Count, "SubType should get deleted");
            #endregion
        }

    }
}
