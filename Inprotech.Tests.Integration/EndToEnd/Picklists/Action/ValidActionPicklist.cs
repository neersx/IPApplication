using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Action
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ValidActionPicklist : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _actionPicklistsDbSetup = new ValidActionPicklistsDbSetup();
            _actionPicklistsDbSetup.Prepare();
        }

        ValidActionPicklistsDbSetup _actionPicklistsDbSetup;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ValidActionPicklistOperations(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);

            SignIn(driver, "/#/configuration/rules/workflows");

            var caseTypePl = new PickList(driver).ByName("ip-search-by-characteristics", "caseType");
            var jurisdictionPl = new PickList(driver).ByName("ip-search-by-characteristics", "jurisdiction");
            var propertyTypePl = new PickList(driver).ByName("ip-search-by-characteristics", "propertyType");

            caseTypePl.SendKeys(ValidActionPicklistsDbSetup.CaseTypeDescription);
            jurisdictionPl.SendKeys(ValidActionPicklistsDbSetup.JurisdictionDescription);
            propertyTypePl.SendKeys(ValidActionPicklistsDbSetup.ValidPropertyTypeDescription);

            var actionPicklist = new PickList(driver).ByName("ip-search-by-characteristics", "action");
            actionPicklist.SearchButton.Click();

            var maintainCaseType = new PickList(driver).ById("pk-case-type");
            var maintainJurisdiction = new PickList(driver).ById("pk-jurisdiction");
            var maintainPropertyType = new PickList(driver).ById("pk-property-type");
            var maintainAction = new PickList(driver).ById("pk-action");

            #region Add Valid Action
            actionPicklist.AddPickListItem();

            var pageDetails = new ValidActionDetailPage(driver);

            #region verify page fields
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.AreEqual(ValidActionPicklistsDbSetup.CaseTypeDescription, maintainCaseType.GetText(), "Ensure CaseType value");
            Assert.AreEqual(ValidActionPicklistsDbSetup.JurisdictionDescription, maintainJurisdiction.Tags.First(), "Ensure JurisdictionValue");
            Assert.AreEqual(ValidActionPicklistsDbSetup.PropertyTypeDescription, maintainPropertyType.GetText(), "Ensure Property Type value");
            #endregion

            maintainAction.EnterAndSelect(ValidActionPicklistsDbSetup.ActionDescription);
            Assert.AreEqual(ValidActionPicklistsDbSetup.ActionDescription, pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure Valid Description value");

            pageDetails.SaveButton.ClickWithTimeout();

            Assert.IsTrue(pageDetails.DefaultsTopic.ActionOrderWindow(driver).Displayed);
            pageDetails.DiscardButton.ClickWithTimeout();

            actionPicklist.SearchFor(ValidActionPicklistsDbSetup.ActionDescription);

            var searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidActionPicklistsDbSetup.ActionDescription, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("e2", searchResults.CellText(0, 1), "Ensure the text is updated");
            Assert.AreEqual("1", searchResults.CellText(0, 2), "Ensure the text is updated");
            #endregion

            #region Edit Valid Action
            actionPicklist.EditRow(0);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsFalse(maintainCaseType.Enabled);
            Assert.IsFalse(maintainJurisdiction.Enabled);
            Assert.IsFalse(maintainPropertyType.Enabled);
            Assert.IsFalse(maintainAction.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();
            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys(ValidActionPicklistsDbSetup.ValidActionDescriptionEdited);
            pageDetails.SaveButton.ClickWithTimeout();
            searchResults = new KendoGrid(driver, "picklistResults");
            actionPicklist.SearchFor(ValidActionPicklistsDbSetup.ValidActionDescriptionEdited);
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidActionPicklistsDbSetup.ValidActionDescriptionEdited, searchResults.CellText(0, 0), "Ensure valid description is updated");
            #endregion

            #region Duplicate Valid Action
            actionPicklist.DuplicateRow(0);
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");
            Assert.IsTrue(maintainCaseType.Enabled);
            Assert.IsTrue(maintainJurisdiction.Enabled);
            Assert.IsTrue(maintainPropertyType.Enabled);
            Assert.IsTrue(maintainAction.Enabled);
            Assert.IsTrue(pageDetails.DefaultsTopic.ValidDescription(driver).Enabled);

            Assert.AreEqual(ValidActionPicklistsDbSetup.CaseTypeDescription, maintainCaseType.GetText(), "Ensure CaseType value");
            Assert.AreEqual(ValidActionPicklistsDbSetup.JurisdictionDescription, maintainJurisdiction.Tags.First(), "Ensure JurisdictionValue");
            Assert.AreEqual(ValidActionPicklistsDbSetup.PropertyTypeDescription, maintainPropertyType.GetText(), "Ensure Property Type value");
            Assert.AreEqual(ValidActionPicklistsDbSetup.ActionDescription, maintainAction.GetText(), "Ensure value");
            Assert.AreEqual(ValidActionPicklistsDbSetup.ValidActionDescriptionEdited, pageDetails.DefaultsTopic.ValidDescription(driver).GetAttribute("value"), "Ensure value");

            #region Error On duplicate action for same combination
            pageDetails.DefaultsTopic.ValidDescription(driver).Clear();
            pageDetails.DefaultsTopic.ValidDescription(driver).SendKeys(ValidActionPicklistsDbSetup.DuplicateActionDescription);
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.True(popups.AlertModal.Modal.Displayed, "Valid Action Already Exists");
            popups.AlertModal.Ok();
            #endregion

            #region Confirmation if action already exists for one country but not for others
            maintainJurisdiction.SendKeys(ValidActionPicklistsDbSetup.JurisdictionDescription2).Blur();

            pageDetails.SaveButton.ClickWithTimeout();
            Assert.True(popups.ConfirmModal.Modal.Displayed, "Some valid Action Already Exists");
            popups.ConfirmModal.Cancel().ClickWithTimeout();
            #endregion

            maintainAction.Clear();
            maintainAction.EnterAndSelect(ValidActionPicklistsDbSetup.DuplicateActionDescription);
            pageDetails.SaveButton.ClickWithTimeout();

            Assert.IsTrue(pageDetails.DefaultsTopic.ActionOrderWindow(driver).Displayed);
            pageDetails.DiscardButton.ClickWithTimeout();

            actionPicklist.SearchFor(ValidActionPicklistsDbSetup.DuplicateActionDescription);

            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(ValidActionPicklistsDbSetup.DuplicateActionDescription, searchResults.CellText(0, 0), "Ensure the text is updated");
            Assert.AreEqual("e3", searchResults.CellText(0, 1), "Ensure the text is updated");
            Assert.AreEqual("1", searchResults.CellText(0, 2), "Ensure the text is updated");
            #endregion

            #region Delete Valid Action
            actionPicklist.SearchFor(ValidActionPicklistsDbSetup.DuplicateActionDescription);
            actionPicklist.DeleteRow(0);

            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            driver.WaitForAngular();

            actionPicklist.SearchFor(ValidActionPicklistsDbSetup.DuplicateActionDescription);

            searchResults = new KendoGrid(driver, "picklistResults");
            Assert.AreEqual(0, searchResults.Rows.Count, "Action should get deleted");
            #endregion
        }
    }
}