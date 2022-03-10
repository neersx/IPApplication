using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.Category
{
    [Category(Categories.E2E)]
    [TestFixture]
    class Category : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var categoryDbSetup = new CategoryDbSetup();
            categoryDbSetup.PrepareEnvironment();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainValidCombinationCategory(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/validcombination/category");

            var caseType = new PickList(driver).ById("case-type-picklist");
            var jurisdiction = new PickList(driver).ById("jurisdiction-picklist");
            var propertyType = new PickList(driver).ById("property-type-picklist");
            var maintainCaseType = new PickList(driver).ById("pk-case-type");
            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");
            var maintainCategory = new PickList(driver).ById("pk-case-category");

            var pageDetails = new CategoryDetailPage(driver);
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();

            #region verify page fields
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            pageDetails.DiscardButton.ClickWithTimeout();
            #endregion

            #region Verify SearchCriteria is prepopulated
            caseType.EnterAndSelect("Properties"); 
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();
            Assert.IsNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            #endregion

            #region Add and Search Valid Category
            Assert.IsFalse(pageDetails.SaveButton.IsDisabled(), "Ensure Save Button is enabled");
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.IsTrue(maintainJurisdiction.HasError, "Required Field");
            Assert.IsTrue(maintainPropertyType.HasError, "Required Field");
            Assert.IsTrue(maintainCategory.HasError, "Required Field");
            Assert.IsTrue(new IpTextField(driver).ByName("validDescription").HasError, "Required Field");
            maintainJurisdiction.EnterAndSelect("e2e");
            maintainPropertyType.EnterAndSelect("Patents");
            maintainCategory.EnterAndSelect(".BIZ");
            pageDetails.SaveButton.ClickWithTimeout();

            caseType.EnterAndSelect("Properties");
            jurisdiction.EnterAndSelect("e2e");
            propertyType.EnterAndSelect("Patents");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();

            var categorySearchResults = new KendoGrid(driver, "validCombinationSearchResults");
            Assert.IsTrue(categorySearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("Properties", categorySearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("e2e - jurisdiction", categorySearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Patents", categorySearchResults.CellText(0, 3), "Ensure value");
            Assert.AreEqual(".BIZ", categorySearchResults.CellText(0, 4), "Ensure value");
            Assert.AreEqual(".BIZ", categorySearchResults.CellText(0, 5), "Ensure value");
            #endregion

            #region Edit Valid Category
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsFalse(maintainCaseType.Enabled);
            Assert.IsFalse(maintainJurisdiction.Enabled);
            Assert.IsFalse(maintainPropertyType.Enabled);
            Assert.IsFalse(maintainCategory.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();
            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys("e2e description");
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(categorySearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("e2e description", categorySearchResults.CellText(0, 5), "Ensure value");
            #endregion

            #region Duplicate Valid Category
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsTrue(maintainCaseType.Enabled);
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.IsTrue(maintainCategory.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            Assert.AreEqual("Properties", maintainCaseType.GetText(), "Ensure value");
            Assert.AreEqual("Patents", maintainPropertyType.GetText(), "Ensure value");
            Assert.AreEqual(".BIZ", maintainCategory.GetText(), "Ensure value");
            Assert.AreEqual("e2e description", pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure value");

            maintainCategory.Clear();
            maintainCategory.EnterAndSelect(".COM");
            pageDetails.SaveButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(categorySearchResults.Rows.Count.Equals(2));
            Assert.AreEqual("Properties", categorySearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("e2e - jurisdiction", categorySearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Patents", categorySearchResults.CellText(0, 3), "Ensure value");
            Assert.AreEqual(".COM", categorySearchResults.CellText(0, 4), "Ensure value");
            Assert.AreEqual(".COM", categorySearchResults.CellText(0, 5), "Ensure value");
            #endregion

            #region Delete Valid Category
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.IsTrue(categorySearchResults.Rows.Count.Equals(0));
            #endregion
        }
    }
}
