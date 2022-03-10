using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.TextsMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TextsMaintenance : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddJurisdictionTexts(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);
            new TextsMaintenanceDbSetUp().Prepare();
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction)
                       .Create();
            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);
            var pageDetails = new TextsMaintenanceDetailPage(driver);

            #region Select Country
            pageDetails.TextsTopic.SearchTextBox(driver).SendKeys(TextsMaintenanceDbSetUp.CountryCode1);
            pageDetails.TextsTopic.SearchButton(driver).WithJs().Click();

            var searchResults = new KendoGrid(driver, "searchResults");

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(TextsMaintenanceDbSetUp.CountryCode1, searchResults.CellText(0, 1), "Search returns record matching code");

            pageDetails.TextsTopic.BulkMenu(driver);
            pageDetails.TextsTopic.SelectPageOnly(driver);
            pageDetails.TextsTopic.EditButton(driver);
            #endregion

            var topic = pageDetails.TextsTopic;

            #region save jurisdiction text
            topic.NavigateTo();
            topic.Add();
            Assert.AreEqual(3, topic.GridRowsCount, "New Row Added");
            pageDetails.Save();
            Assert.True(popups.AlertModal.Modal.Displayed, "Mandatory field required.");
            popups.AlertModal.Ok();
            topic.TextTypePickListByRow(topic.Grid.Rows[2]).EnterAndSelect(TextsMaintenanceDbSetUp.TextType1);
            topic.PropertyTypePickListByRow(topic.Grid.Rows[2]).EnterAndSelect(TextsMaintenanceDbSetUp.PropertyTypeDesc1);
            Assert.True(pageDetails.SaveButton.IsDisabled(), "In case of duplicate row save button should be disabled.");
            topic.TextTypePickListByRow(topic.Grid.Rows[2]).EnterAndSelect(TextsMaintenanceDbSetUp.TextType3);
            pageDetails.Save();
            topic.NavigateTo();

            var textTypeGridSearchResults = new KendoGrid(driver, "textsGrid");
            Assert.AreEqual(3, topic.NumberOfRecords(), "Topic displays count");

            Assert.AreEqual(TextsMaintenanceDbSetUp.TextType3, textTypeGridSearchResults.CellText(2, 1), "Search returns record matching Code");
            Assert.AreEqual(TextsMaintenanceDbSetUp.PropertyTypeDesc1, topic.PropertyTypePickListByRow(topic.Grid.Rows[2]).GetText(), "Property Type added.");
            #endregion

            #region edit jurisdiction text
            topic.PropertyTypePickListByRow(topic.Grid.Rows[2]).EnterAndSelect(TextsMaintenanceDbSetUp.PropertyTypeDesc3);
            pageDetails.Save();

            topic.NavigateTo();
            Assert.AreEqual(TextsMaintenanceDbSetUp.PropertyTypeDesc3, topic.PropertyTypePickListByRow(topic.Grid.Rows[2]).GetText(), "Property Type added.");
            #endregion

            #region delete jurisdiction text
            topic.Grid.ToggleDelete(0);
            topic.Grid.ToggleDelete(1);

            pageDetails.Save();
            Assert.AreEqual(1, topic.GridRowsCount, "only deletes the row which was marked as deleted");
            #endregion
        }
    }
}
