using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.Relationship
{
    [Category(Categories.E2E)]
    [TestFixture]
    class Relationship : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var relationshipDbSetup = new RelationshipDbSetup();
            relationshipDbSetup.PrepareEnvironment();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainValidCombinationRelationship(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/validcombination/relationship");

            var jurisdiction = new PickList(driver).ById("jurisdiction-picklist");
            var propertyType = new PickList(driver).ById("property-type-picklist");
            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");
            var maintainRelationship = new PickList(driver).ById("pk-relationship");
            var maintainReciprocalRelationship = new PickList(driver).ById("pk-recip-relationship");

            var pageDetails = new RelationshipDetailPage(driver);
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

            #region Add and Search Valid Relationship
            Assert.IsFalse(pageDetails.SaveButton.IsDisabled(), "Ensure Save Button is enabled");
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.IsTrue(maintainPropertyType.HasError, "Required Field");
            Assert.IsTrue(maintainRelationship.HasError, "Required Field");
            maintainPropertyType.EnterAndSelect("Patents");
            maintainRelationship.EnterAndSelect("Agreement");
            pageDetails.SaveButton.ClickWithTimeout();

            jurisdiction.EnterAndSelect("e2e");
            propertyType.EnterAndSelect("Patents");
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();

            var relationshipSearchResults = new KendoGrid(driver, "validCombinationSearchResults");
            Assert.IsTrue(relationshipSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("e2e - jurisdiction", relationshipSearchResults.CellText(0, 1), "Ensure value");
            Assert.AreEqual("Patents", relationshipSearchResults.CellText(0, 2), "Ensure value");
            Assert.AreEqual("Agreement", relationshipSearchResults.CellText(0, 3), "Ensure value");
            #endregion

            #region Edit Valid Relationship
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsFalse(maintainJurisdiction.Enabled);
            Assert.IsFalse(maintainPropertyType.Enabled);
            Assert.IsFalse(maintainRelationship.Enabled);
            Assert.IsTrue(maintainReciprocalRelationship.Enabled);

            maintainReciprocalRelationship.EnterAndSelect("Agreement");
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(relationshipSearchResults.Rows.Count.Equals(1));
            Assert.AreEqual("Agreement", relationshipSearchResults.CellText(0, 4), "Ensure value");
            #endregion

            #region Duplicate Valid Relationship
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.IsTrue(maintainRelationship.Enabled);
            Assert.IsTrue(maintainReciprocalRelationship.Enabled);

            Assert.AreEqual("Patents", maintainPropertyType.GetText(), "Ensure value");
            Assert.AreEqual("Agreement", maintainRelationship.GetText(), "Ensure value");
            Assert.AreEqual("Agreement", maintainReciprocalRelationship.GetText(), "Ensure value");

            maintainRelationship.Clear();
            maintainRelationship.EnterAndSelect("Assignment/Recordal");
            pageDetails.SaveButton.ClickWithTimeout();

            pageDetails.DefaultsTopic.SearchButton(driver).ClickWithTimeout();
            Assert.IsTrue(relationshipSearchResults.Rows.Count.Equals(2));
            Assert.AreEqual("e2e - jurisdiction", relationshipSearchResults.CellText(1, 1), "Ensure value");
            Assert.AreEqual("Patents", relationshipSearchResults.CellText(1, 2), "Ensure value");
            Assert.AreEqual("Assignment/Recordal", relationshipSearchResults.CellText(1, 3), "Ensure value");
            Assert.AreEqual("Agreement", relationshipSearchResults.CellText(1, 4), "Ensure value");
            #endregion

            #region Delete Valid Relationship
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectPage(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.IsTrue(relationshipSearchResults.Rows.Count.Equals(0));
            #endregion
        }
    }
}
