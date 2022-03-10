using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.Basis
{
    [Category(Categories.E2E)]
    [TestFixture]
    class Basis : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var basisDbSetup = new BasisDbSetup();
            basisDbSetup.PrepareEnvironment();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainValidCombinationBasis(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/validcombination/basis");

            var caseType = new PickList(driver).ById("case-type-picklist");
            var jurisdiction = new PickList(driver).ById("jurisdiction-picklist");
            var propertyType = new PickList(driver).ById("property-type-picklist");
            var maintainCaseType = new PickList(driver).ById("pk-case-type");
            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");
            var maintainCategory = new PickList(driver).ById("pk-case-category");
            var maintainBasis = new PickList(driver).ById("pk-basis");

            var pageDetails = new BasisDetailPage(driver);
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

            #region Add and Search Valid Basis
            Assert.IsFalse(pageDetails.SaveButton.IsDisabled(), "Ensure Save Button is enabled");
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.IsTrue(maintainJurisdiction.HasError, "Required Field");
            Assert.IsTrue(maintainPropertyType.HasError, "Required Field");
            Assert.IsTrue(maintainBasis.HasError, "Required Field");
            Assert.IsTrue(new IpTextField(driver).ByName("validDescription").HasError, "Required Field");
            maintainJurisdiction.EnterAndSelect("e2e");
            maintainPropertyType.EnterAndSelect("Patents");
            maintainCategory.EnterAndSelect(".BIZ");
            maintainBasis.EnterAndSelect("Claiming Paris Convention");
            pageDetails.SaveButton.ClickWithTimeout();

            caseType.EnterAndSelect("Properties");
            jurisdiction.EnterAndSelect("e2e");
            propertyType.EnterAndSelect("Patents");

            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();

            var basisSearchResults = new KendoGrid(driver, "validCombinationSearchResults");
            Assert.IsTrue(basisSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("Properties", basisSearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("e2e - jurisdiction", basisSearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Patents", basisSearchResults.CellText(0, 3), "Ensure value");
            Assert.AreEqual(".BIZ", basisSearchResults.CellText(0, 4), "Ensure value");
            Assert.AreEqual("Claiming Paris Convention", basisSearchResults.CellText(0, 5), "Ensure value");
            Assert.AreEqual("Claiming Paris Convention", basisSearchResults.CellText(0, 6), "Ensure value");
            #endregion

            #region Edit Valid Basis
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsFalse(maintainCaseType.Enabled);
            Assert.IsFalse(maintainJurisdiction.Enabled);
            Assert.IsFalse(maintainPropertyType.Enabled);
            Assert.IsFalse(maintainCategory.Enabled);
            Assert.IsFalse(maintainBasis.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();
            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys("e2e description");
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(basisSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("e2e description", basisSearchResults.CellText(0, 6), "Ensure value");
            #endregion

            #region Duplicate Valid Basis
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsTrue(maintainCaseType.Enabled);
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.IsTrue(maintainCategory.Enabled);
            Assert.IsTrue(maintainBasis.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            Assert.AreEqual("Properties", maintainCaseType.GetText(), "Ensure value");
            Assert.AreEqual("Patents", maintainPropertyType.GetText(), "Ensure value");
            Assert.AreEqual(".BIZ", maintainCategory.GetText(), "Ensure value");
            Assert.AreEqual("Claiming Paris Convention", maintainBasis.GetText(), "Ensure value");
            Assert.AreEqual("e2e description", pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure value");

            maintainBasis.Clear();
            maintainBasis.EnterAndSelect("Non-Convention");
            pageDetails.SaveButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(basisSearchResults.Rows.Count.Equals(2));
            Assert.AreEqual("Properties", basisSearchResults.CellText(1, 1), "Ensure value");
            Assert.AreEqual("e2e - jurisdiction", basisSearchResults.CellText(1, 2), "Ensure value");
            Assert.AreEqual("Patents", basisSearchResults.CellText(1, 3), "Ensure value");
            Assert.AreEqual(".BIZ", basisSearchResults.CellText(1, 4), "Ensure value");
            Assert.AreEqual("Non-Convention", basisSearchResults.CellText(1, 5), "Ensure value");
            Assert.AreEqual("Non-Convention", basisSearchResults.CellText(1, 6), "Ensure value");
            #endregion

            #region Delete Valid Basis
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.IsTrue(basisSearchResults.Rows.Count.Equals(0));
            #endregion
        }
    }
}