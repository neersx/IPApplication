using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;
using System.Linq;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.PropertyType
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ValidPropertyTypePicklist : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _propertyTypePicklistsDbSetup = new ValidPropertyTypeDbSetup();
            _propertyTypePicklistsDbSetup.Prepare();
        }

        ValidPropertyTypeDbSetup _propertyTypePicklistsDbSetup;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ValidPropertyTypePicklistOperations(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);

            SignIn(driver, "/#/configuration/rules/workflows");

            var jurisdictionPl = new PickList(driver).ByName("ip-search-by-characteristics", "jurisdiction");
            var propertyTypePicklist = new PickList(driver).ByName("ip-search-by-characteristics", "propertyType");

            jurisdictionPl.SendKeys(ValidPropertyTypeDbSetup.JurisdictionDescription).Blur();
            propertyTypePicklist.OpenPickList();

            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");

            #region Add Valid PropertyType
            propertyTypePicklist.AddPickListItem();

            var pageDetails = new ValidPropertyTypeDetailPage(driver);

            #region verify page fields
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.AreEqual(ValidPropertyTypeDbSetup.JurisdictionDescription, maintainJurisdiction.Tags.First(), "Ensure JurisdictionValue");
            #endregion

            maintainPropertyType.EnterAndSelect(ValidPropertyTypeDbSetup.ValidPropertyTypeDescription);
            Assert.AreEqual(ValidPropertyTypeDbSetup.ValidPropertyTypeDescription, pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure Valid Description value");
            pageDetails.DefaultsTopic.AnnuityCycleOffsetRadioButton(driver).Click();
            Assert.IsFalse(pageDetails.DefaultsTopic.AnnuityOffset(driver).Enabled);
            pageDetails.DefaultsTopic.AnnuityCycleOffset(driver).SendKeys("1");
            pageDetails.SaveButton.ClickWithTimeout();

            propertyTypePicklist.SearchFor(ValidPropertyTypeDbSetup.ValidPropertyTypeDescription);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidPropertyTypeDbSetup.ValidPropertyTypeDescription, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("_", searchResults.CellText(0, 1), "Ensure the text is updated");
            #endregion

            #region Edit Valid PropertyType
            propertyTypePicklist.EditRow(0);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsFalse(maintainJurisdiction.Enabled);
            Assert.IsFalse(maintainPropertyType.Enabled);
            Assert.AreEqual("1", pageDetails.DefaultsTopic.AnnuityCycleOffset(driver).GetAttribute("value"), "Ensure value");
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();
            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys(ValidPropertyTypeDbSetup.ValidPropertyTypeEdited);
            pageDetails.SaveButton.ClickWithTimeout();
            searchResults = new KendoGrid(driver, "picklistResults");
            propertyTypePicklist.SearchFor(ValidPropertyTypeDbSetup.ValidPropertyTypeEdited);
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidPropertyTypeDbSetup.ValidPropertyTypeEdited, searchResults.CellText(0, 0), "Ensure valid description is updated");
            #endregion

            #region Duplicate Valid PropertyType
            propertyTypePicklist.DuplicateRow(0);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            Assert.AreEqual(ValidPropertyTypeDbSetup.JurisdictionDescription, maintainJurisdiction.Tags.First(), "Ensure JurisdictionValue");
            Assert.AreEqual(ValidPropertyTypeDbSetup.ValidPropertyTypeDescription, maintainPropertyType.GetText(), "Ensure Property Type value");
            Assert.AreEqual(ValidPropertyTypeDbSetup.ValidPropertyTypeEdited, pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure value");

            #region Error On duplicate PropertyType for same combination
            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();
            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys(ValidPropertyTypeDbSetup.DuplicateValidPropertyType);
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.True(popups.AlertModal.Modal.Displayed, "Valid PropertyType Already Exists");
            popups.AlertModal.Ok();
            #endregion

            #region Confirmation if PropertyType already exists for one country but not for others
            maintainJurisdiction.SendKeys(ValidPropertyTypeDbSetup.JurisdictionDescription2).Blur();

            pageDetails.SaveButton.ClickWithTimeout();
            Assert.True(popups.ConfirmModal.Modal.Displayed, "Some valid PropertyType Already Exists");
            popups.ConfirmModal.Cancel().ClickWithTimeout();
            #endregion

            maintainPropertyType.Clear();
            maintainPropertyType.EnterAndSelect(ValidPropertyTypeDbSetup.DuplicateValidPropertyType);
            pageDetails.SaveButton.ClickWithTimeout();
            propertyTypePicklist.SearchFor(ValidPropertyTypeDbSetup.DuplicateValidPropertyType);

            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidPropertyTypeDbSetup.DuplicateValidPropertyType, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("@", searchResults.CellText(0, 1), "Ensure the text is updated");
            #endregion

            #region Delete Valid PropertyType
            propertyTypePicklist.SearchFor(ValidPropertyTypeDbSetup.DuplicateValidPropertyType);
            propertyTypePicklist.DeleteRow(0);

            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            driver.WaitForAngular();

            propertyTypePicklist.SearchFor(ValidPropertyTypeDbSetup.DuplicateValidPropertyType);

            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, searchResults.Rows.Count, "PropertyType should get deleted");
            #endregion
        }
    }
}