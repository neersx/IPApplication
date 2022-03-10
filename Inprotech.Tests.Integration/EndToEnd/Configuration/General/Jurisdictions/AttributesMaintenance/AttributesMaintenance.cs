using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.AttributesMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class AttributesMaintenance : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddJurisdictionAttribute(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var popups = new CommonPopups(driver);

            new AttributesMaintenanceDbSetUp().Prepare();
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction)
                       .Create();

            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);
            var pageDetails = new AttributesMaintenanceDetailPage(driver);

            #region Select Country
            pageDetails.AttributesTopic.SearchTextBox(driver).SendKeys(AttributesMaintenanceDbSetUp.CountryCode1);
            pageDetails.AttributesTopic.SearchButton(driver).WithJs().Click();

            var searchResults = new KendoGrid(driver, "searchResults");

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(AttributesMaintenanceDbSetUp.CountryCode1, searchResults.CellText(0, 1), "Search returns record matching code");

            pageDetails.AttributesTopic.BulkMenu(driver);
            pageDetails.AttributesTopic.SelectPageOnly(driver);
            pageDetails.AttributesTopic.EditButton(driver);
            #endregion

            var topic = pageDetails.AttributesTopic;

            topic.NavigateTo();
            topic.Add();
            Assert.AreEqual(3, topic.GridRowsCount, "New Row Added");
            topic.AttributeTypeDropDownByRow(topic.Grid.Rows[2]).Input.SelectByText(AttributesMaintenanceDbSetUp.TableType2);
            topic.AttributeValueDropDownByRow(topic.Grid.Rows[2]).Input.SelectByText(AttributesMaintenanceDbSetUp.TableCode4);
            pageDetails.Save();
            topic.NavigateTo();

            Assert.AreEqual(AttributesMaintenanceDbSetUp.TableType2, topic.AttributeTypeDropDownByRow(topic.Grid.Rows[2]).Text, "Attribute added.");
            Assert.AreEqual(AttributesMaintenanceDbSetUp.TableCode4, topic.AttributeValueDropDownByRow(topic.Grid.Rows[2]).Text, "Attribute added.");

            #region Maximum attributes error
            topic.Add();
            Assert.AreEqual(4, topic.GridRowsCount, "New Row Added");
            topic.AttributeTypeDropDownByRow(topic.Grid.Rows[3]).Input.SelectByText(AttributesMaintenanceDbSetUp.TableType1);
            topic.AttributeValueDropDownByRow(topic.Grid.Rows[3]).Input.SelectByText(AttributesMaintenanceDbSetUp.TableCode2);
            pageDetails.Save();
            Assert.True(popups.AlertModal.Modal.Displayed, "Maximum attributes limit exceeded");
            popups.AlertModal.Ok();

            topic.Grid.ToggleDelete(3);
            Assert.AreEqual(3, topic.GridRowsCount, "Last Row Removed");
            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void UpdateJurisdictionAttribute(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            new AttributesMaintenanceDbSetUp().Prepare();
            var user = new Users()
                .WithPermission(ApplicationTask.MaintainJurisdiction)
                .Create();
            
            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);

            var pageDetails = new AttributesMaintenanceDetailPage(driver);
            #region Select Country
            pageDetails.AttributesTopic.SearchTextBox(driver).SendKeys(AttributesMaintenanceDbSetUp.CountryCode1);
            pageDetails.AttributesTopic.SearchButton(driver).WithJs().Click();

            var searchResults = new KendoGrid(driver, "searchResults");

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(AttributesMaintenanceDbSetUp.CountryCode1, searchResults.CellText(0, 1), "Search returns record matching code");

            pageDetails.AttributesTopic.BulkMenu(driver);
            pageDetails.AttributesTopic.SelectPageOnly(driver);
            pageDetails.AttributesTopic.EditButton(driver);
            #endregion

            var topic = pageDetails.AttributesTopic;

            topic.NavigateTo();
            topic.AttributeValueDropDownByRow(topic.Grid.Rows[0]).Input.SelectByText(AttributesMaintenanceDbSetUp.TableCode2);

            pageDetails.Save();
            topic.NavigateTo();

            Assert.AreEqual(AttributesMaintenanceDbSetUp.TableType1, topic.AttributeTypeDropDownByRow(topic.Grid.Rows[0]).Text, "Attribute updated.");
            Assert.AreEqual(AttributesMaintenanceDbSetUp.TableCode2, topic.AttributeValueDropDownByRow(topic.Grid.Rows[0]).Text, "Attribute updated.");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteJurisdictionAttribute(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            new AttributesMaintenanceDbSetUp().Prepare();
            var popups = new CommonPopups(driver);
            var user = new Users()
                .WithPermission(ApplicationTask.MaintainJurisdiction)
                .Create();
            
            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);
            var pageDetails = new AttributesMaintenanceDetailPage(driver);
            #region Select Country
            pageDetails.AttributesTopic.SearchTextBox(driver).SendKeys(AttributesMaintenanceDbSetUp.CountryCode1);
            pageDetails.AttributesTopic.SearchButton(driver).WithJs().Click();

            var searchResults = new KendoGrid(driver, "searchResults");

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(AttributesMaintenanceDbSetUp.CountryCode1, searchResults.CellText(0, 1), "Search returns record matching code");

            pageDetails.AttributesTopic.BulkMenu(driver);
            pageDetails.AttributesTopic.SelectPageOnly(driver);
            pageDetails.AttributesTopic.EditButton(driver);
            #endregion

            var topic = pageDetails.AttributesTopic;

            topic.NavigateTo();
            topic.Grid.ToggleDelete(0);

            pageDetails.Save();
            Assert.True(popups.AlertModal.Modal.Displayed, "Maximum attributes limit exceeded");
            popups.AlertModal.Ok();

            topic.NavigateTo();
            topic.Grid.ToggleDelete(0);
            topic.Grid.ToggleDelete(1);

            pageDetails.Save();
            Assert.AreEqual(1, topic.GridRowsCount, "only deletes the row which was marked as deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ClickPriorArtCheckBoxAndSave(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            new AttributesMaintenanceDbSetUp().Prepare();
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction)
                       .Create();

            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);
            var pageDetails = new AttributesMaintenanceDetailPage(driver);
            #region Select Country
            pageDetails.AttributesTopic.SearchTextBox(driver).SendKeys(AttributesMaintenanceDbSetUp.CountryCode1);
            pageDetails.AttributesTopic.SearchButton(driver).WithJs().Click();

            var searchResults = new KendoGrid(driver, "searchResults");

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(AttributesMaintenanceDbSetUp.CountryCode1, searchResults.CellText(0, 1), "Search returns record matching code");

            pageDetails.AttributesTopic.BulkMenu(driver);
            pageDetails.AttributesTopic.SelectPageOnly(driver);
            pageDetails.AttributesTopic.EditButton(driver);
            #endregion

            var topic = pageDetails.AttributesTopic;

            topic.NavigateTo();

            Assert.AreEqual(pageDetails.SaveButton.Enabled, false);
            var initialState = topic.ReportPriorArtCheckBox.IsChecked;
            topic.ReportPriorArtCheckBox.Click();
            pageDetails.SaveButton.ClickWithTimeout();
            Assert.AreEqual(topic.ReportPriorArtCheckBox.IsChecked, !initialState);
        }
    }
}
