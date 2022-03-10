using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.Status
{
    [Category(Categories.E2E)]
    [TestFixture]
    class Status : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var statusDbSetup = new StatusDbSetup();
            statusDbSetup.PrepareEnvironment();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainValidCombinationStatus(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/validcombination/status");

            var caseType = new PickList(driver).ById("case-type-picklist");
            var jurisdiction = new PickList(driver).ById("jurisdiction-picklist");
            var propertyType = new PickList(driver).ById("property-type-picklist");
            var maintainCaseType = new PickList(driver).ById("pk-case-type");
            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");
            var maintainStatus = new PickList(driver).ById("pk-status");

            var pageDetails = new StatusDetailPage(driver);
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

            #region Add and Search Valid Status
            Assert.IsFalse(pageDetails.SaveButton.IsDisabled(), "Ensure Save Button is enabled");
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.IsTrue(maintainJurisdiction.HasError, "Required Field");
            Assert.IsTrue(maintainPropertyType.HasError, "Required Field");
            Assert.IsTrue(maintainStatus.HasError, "Required Field");
            maintainJurisdiction.EnterAndSelect("e2e");
            maintainPropertyType.EnterAndSelect("Patents");
            maintainStatus.EnterAndSelect("Abandoned by client");
            pageDetails.SaveButton.ClickWithTimeout();

            caseType.EnterAndSelect("Properties");
            jurisdiction.EnterAndSelect("e2e");
            propertyType.EnterAndSelect("Patents");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();

            var statusSearchResults = new KendoGrid(driver, "validCombinationSearchResults");
            Assert.IsTrue(statusSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("Properties", statusSearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("e2e - jurisdiction", statusSearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Patents", statusSearchResults.CellText(0, 3), "Ensure value");
            Assert.AreEqual("Abandoned by client", statusSearchResults.CellText(0, 4), "Ensure value");
            #endregion

            #region Duplicate Valid Status
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsTrue(maintainCaseType.Enabled);
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.IsTrue(maintainStatus.Enabled);

            Assert.AreEqual("Properties", maintainCaseType.GetText(), "Ensure value");
            Assert.AreEqual("Patents", maintainPropertyType.GetText(), "Ensure value");
            Assert.AreEqual("Abandoned by client", maintainStatus.GetText(), "Ensure value");

            maintainStatus.Clear();
            maintainStatus.EnterAndSelect("Application allowed");
            pageDetails.SaveButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(statusSearchResults.Rows.Count.Equals(2));
            Assert.AreEqual("Properties", statusSearchResults.CellText(1, 1), "Ensure value");
            Assert.AreEqual("e2e - jurisdiction", statusSearchResults.CellText(1, 2), "Ensure value");
            Assert.AreEqual("Patents", statusSearchResults.CellText(1, 3), "Ensure value");
            Assert.AreEqual("Application allowed", statusSearchResults.CellText(1, 4), "Ensure value");
            #endregion

            #region Delete Valid Status
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.IsTrue(statusSearchResults.Rows.Count.Equals(0));
            #endregion
        }
    }
}
