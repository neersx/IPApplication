using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.SubType
{
    [Category(Categories.E2E)]
    [TestFixture]
    class SubType : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var subTypeDbSetup = new SubTypeDbSetup();
            subTypeDbSetup.PrepareEnvironment();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainValidCombinationSubType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/validcombination/subtype");

            var caseType = new PickList(driver).ById("case-type-picklist");
            var jurisdiction = new PickList(driver).ById("jurisdiction-picklist");
            var propertyType = new PickList(driver).ById("property-type-picklist");
            var maintainCaseType = new PickList(driver).ById("pk-case-type");
            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");
            var maintainCategory = new PickList(driver).ById("pk-case-category");
            var maintainSubType = new PickList(driver).ById("pk-sub-type");

            var pageDetails = new SubTypeDetailPage(driver);
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

            #region Add and Search Valid SubType
            Assert.IsFalse(pageDetails.SaveButton.IsDisabled(), "Ensure Save Button is enabled");
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.IsTrue(maintainJurisdiction.HasError, "Required Field");
            Assert.IsTrue(maintainPropertyType.HasError, "Required Field");
            Assert.IsTrue(maintainCategory.HasError, "Required Field");
            Assert.IsTrue(maintainSubType.HasError, "Required Field");
            Assert.IsTrue(new IpTextField(driver).ByName("validDescription").HasError, "Required Field");
            maintainJurisdiction.EnterAndSelect("e2e");
            maintainPropertyType.EnterAndSelect("Patents");
            maintainCategory.EnterAndSelect(".BIZ");
            maintainSubType.EnterAndSelect("5 yearly renewals");
            pageDetails.SaveButton.ClickWithTimeout();

            caseType.EnterAndSelect("Properties");
            jurisdiction.EnterAndSelect("e2e");
            propertyType.EnterAndSelect("Patents");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();

            var subTypeSearchResults = new KendoGrid(driver, "validCombinationSearchResults");
            Assert.IsTrue(subTypeSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("Properties", subTypeSearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("e2e - jurisdiction", subTypeSearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Patents", subTypeSearchResults.CellText(0, 3), "Ensure value");
            Assert.AreEqual(".BIZ", subTypeSearchResults.CellText(0, 4), "Ensure value");
            Assert.AreEqual("5 yearly renewals", subTypeSearchResults.CellText(0, 5), "Ensure value");
            Assert.AreEqual("5 yearly renewals", subTypeSearchResults.CellText(0, 6), "Ensure value");
            #endregion

            #region Edit Valid SubType
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsFalse(maintainCaseType.Enabled);
            Assert.IsFalse(maintainJurisdiction.Enabled);
            Assert.IsFalse(maintainPropertyType.Enabled);
            Assert.IsFalse(maintainCategory.Enabled);
            Assert.IsFalse(maintainSubType.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();
            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys("e2e description");
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(subTypeSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("e2e description", subTypeSearchResults.CellText(0, 6), "Ensure value");
            #endregion

            #region Duplicate Valid SubType
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsTrue(maintainCaseType.Enabled);
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.IsTrue(maintainCategory.Enabled);
            Assert.IsTrue(maintainSubType.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            Assert.AreEqual("Properties", maintainCaseType.GetText(), "Ensure value");
            Assert.AreEqual("Patents", maintainPropertyType.GetText(), "Ensure value");
            Assert.AreEqual(".BIZ", maintainCategory.GetText(), "Ensure value");
            Assert.AreEqual("5 yearly renewals", maintainSubType.GetText(), "Ensure value");
            Assert.AreEqual("e2e description", pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure value");

            maintainSubType.Clear();
            maintainSubType.EnterAndSelect("Certification Mark");
            driver.WaitForBlockUi();
            pageDetails.SaveButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(subTypeSearchResults.Rows.Count.Equals(2));
            Assert.AreEqual("Properties", subTypeSearchResults.CellText(1, 1), "Ensure value");
            Assert.AreEqual("e2e - jurisdiction", subTypeSearchResults.CellText(1, 2), "Ensure value");
            Assert.AreEqual("Patents", subTypeSearchResults.CellText(1, 3), "Ensure value");
            Assert.AreEqual(".BIZ", subTypeSearchResults.CellText(1, 4), "Ensure value");
            Assert.AreEqual("Certification Mark", subTypeSearchResults.CellText(1, 5), "Ensure value");
            Assert.AreEqual("Certification Mark", subTypeSearchResults.CellText(1, 6), "Ensure value");
            #endregion

            #region Delete Valid SubType
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.IsTrue(subTypeSearchResults.Rows.Count.Equals(0));
            #endregion
        }
    }
}