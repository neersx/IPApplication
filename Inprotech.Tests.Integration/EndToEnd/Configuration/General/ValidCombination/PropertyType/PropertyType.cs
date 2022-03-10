using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.PropertyType
{
    [Category(Categories.E2E)]
    [TestFixture]
    class PropertyType : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var propertyTypeDbSetup = new PropertyTypeDbSetup();
            propertyTypeDbSetup.PrepareEnvironment();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainValidCombinationPropertyType(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/validcombination/propertytype");

            var jurisdiction = new PickList(driver).ById("jurisdiction-picklist");
            new PickList(driver).ById("property-type-picklist");
            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");

            var pageDetails = new PropertyTypeDetailPage(driver);

            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();

            #region verify page fields
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            pageDetails.DiscardButton.ClickWithTimeout();
            #endregion

            #region Verify SearchCriteria is prepopulated
            jurisdiction.EnterAndSelect("e2e");
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();
            Assert.IsNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            #endregion

            #region Add and Search Valid Property Type
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.IsTrue(maintainPropertyType.HasError, "Required Field");
            Assert.IsTrue(new IpTextField(driver).ByName("validDescription").HasError, "Required Field");
            maintainPropertyType.EnterAndSelect("Patents");
            pageDetails.DefaultsTopic.AnnuityOffset(driver).SendKeys("1");
            pageDetails.SaveButton.ClickWithTimeout();

            jurisdiction.EnterAndSelect("e2e");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();

            var propertyTypeSearchResults = new KendoGrid(driver, "validCombinationSearchResults");
            Assert.IsTrue(propertyTypeSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("e2e - jurisdiction", propertyTypeSearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("Patents", propertyTypeSearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Patents", propertyTypeSearchResults.CellText(0, 3), "Ensure value");
            #endregion

            #region Edit Valid Property Type
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsFalse(maintainJurisdiction.Enabled);
            Assert.IsFalse(maintainPropertyType.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();
            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys("e2e description");
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(propertyTypeSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("e2e description", propertyTypeSearchResults.CellText(0, 3), "Ensure value");
            #endregion

            #region Duplicate Valid Property Type
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            Assert.AreEqual("Patents", maintainPropertyType.GetText(), "Ensure value");
            Assert.AreEqual("e2e description", pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure value");
            Assert.AreEqual("1", pageDetails.DefaultsTopic.AnnuityOffset(driver).GetAttribute("value"), "Ensure value");

            maintainPropertyType.Clear();
            maintainPropertyType.EnterAndSelect("Trade Marks");
            pageDetails.SaveButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(propertyTypeSearchResults.Rows.Count.Equals(2));
            Assert.AreEqual("e2e - jurisdiction", propertyTypeSearchResults.CellText(1, 1), "Ensure value");
            Assert.AreEqual("Trade Marks", propertyTypeSearchResults.CellText(1, 2), "Ensure value");
            Assert.AreEqual("Trade Marks", propertyTypeSearchResults.CellText(1, 3), "Ensure value");
            #endregion

            #region Delete Valid Property Type
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.IsTrue(propertyTypeSearchResults.Rows.Count.Equals(0));
            #endregion
        }
    }
}
