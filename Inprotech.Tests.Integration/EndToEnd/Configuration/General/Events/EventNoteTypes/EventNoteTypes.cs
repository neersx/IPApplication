using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Events.EventNoteTypes
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EventNoteTypes : IntegrationTest
    {

        EventNoteTypesDbSetup _eventNoteTypesDbSetup;

        [SetUp]
        public void Setup()
        {
            _eventNoteTypesDbSetup = new EventNoteTypesDbSetup();
            _eventNoteTypesDbSetup.Prepare();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EventNoteTypeMaintenance(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/general/events/eventnotetypes");

            #region search by code
            var pageDetails = new EventNoteTypesDetailPage(driver);
            pageDetails.DefaultsTopic.SearchEventNoteBox(driver).SendKeys(EventNoteTypesDbSetup.EventNoteTypeDescription);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "EventNote type description should get searched");
            #endregion

            #region Add
            pageDetails.DefaultsTopic.AddButton(driver).ClickWithTimeout();
            Assert.AreEqual(string.Empty, pageDetails.DefaultsTopic.Description(driver).GetAttribute("value"), "Ensure Description is equal");
            Assert.IsNull(pageDetails.DefaultsTopic.Description(driver).GetAttribute("disabled"), "Ensure Description is enabled");
            Assert.IsNull(pageDetails.DefaultsTopic.SharingAllowedCheckbox(driver).GetAttribute("disabled"), "Ensure Individual checkbox is enabled");
            Assert.IsNull(pageDetails.DefaultsTopic.IsExternalCheckbox(driver).GetAttribute("disabled"), "Ensure Organisation checkbox is enabled");
            Assert.IsNotNull(pageDetails.SaveButton.GetAttribute("disabled"), "Ensure Save Button is disabled");
            Assert.IsNull(pageDetails.DiscardButton.GetAttribute("disabled"), "Ensure Discard Button is enabled");

            pageDetails.DefaultsTopic.Description(driver).SendKeys(EventNoteTypesDbSetup.EventNoteTypeDescription);
            driver.WaitForAngular();
            pageDetails.SaveButton.ClickWithTimeout();

            var popups = new CommonPopups(driver);
            popups.AlertModal.Ok();
            Assert.IsTrue(new TextField(driver, "description").HasError, "Description should be unique");

            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(EventNoteTypesDbSetup.EventNoteTypeToBeAdded);
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchEventNoteBox(driver).SendKeys(EventNoteTypesDbSetup.EventNoteTypeToBeAdded);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();

            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(EventNoteTypesDbSetup.EventNoteTypeToBeAdded, searchResults.CellText(0, 1), "Ensure the event note type is added");
            #endregion

            #region Duplicate EventNote Type
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchEventNoteBox(driver).SendKeys(EventNoteTypesDbSetup.EventNoteTypeDescription);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Event Note type should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDuplicate(driver);
            Assert.IsNull(pageDetails.DefaultsTopic.Description(driver).GetAttribute("disabled"), "Ensure Code is enabled");
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(EventNoteTypesDbSetup.EventNoteTypeToBeDuplicate);
            driver.WaitForAngularWithTimeout();
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchEventNoteBox(driver).SendKeys(EventNoteTypesDbSetup.EventNoteTypeToBeDuplicate);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(EventNoteTypesDbSetup.EventNoteTypeToBeDuplicate, searchResults.CellText(0, 1), "Ensure the text is updated");
            #endregion

            #region Edit EventNote Type
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchEventNoteBox(driver).SendKeys(EventNoteTypesDbSetup.EventNoteTypeDescription);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "Record should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnEdit(driver);
            pageDetails.DefaultsTopic.Description(driver).Clear();
            pageDetails.DefaultsTopic.Description(driver).SendKeys(EventNoteTypesDbSetup.EventNoteTypeToBeEdit);
            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.DiscardButton.ClickWithTimeout();
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchEventNoteBox(driver).SendKeys(EventNoteTypesDbSetup.EventNoteTypeToBeEdit);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(EventNoteTypesDbSetup.EventNoteTypeToBeEdit, searchResults.CellText(0, 1), "Ensure the text is updated");
            #endregion

            #region Delete Successfully
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchEventNoteBox(driver).SendKeys(EventNoteTypesDbSetup.EventNoteTypeToBeEdit);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.AreEqual(0, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "EventNote type code should not get searched as deleted");
            #endregion

            #region Unable to complete as records in use
            pageDetails.DefaultsTopic.ClearButton(driver).Click();
            pageDetails.DefaultsTopic.SearchEventNoteBox(driver).SendKeys(EventNoteTypesDbSetup.EventNoteTypeInUse);
            pageDetails.DefaultsTopic.SearchButton(driver).WithJs().Click();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "EventNote should get searched");
            pageDetails.DefaultsTopic.ClickOnBulkActionMenu(driver);
            pageDetails.DefaultsTopic.ClickOnSelectAll(driver);
            pageDetails.DefaultsTopic.ClickOnDelete(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            popups.AlertModal.Ok();
            Assert.AreEqual(1, pageDetails.DefaultsTopic.GetSearchResultCount(driver), "EventNote should get searched as in use");
            #endregion
        }
    }
}
