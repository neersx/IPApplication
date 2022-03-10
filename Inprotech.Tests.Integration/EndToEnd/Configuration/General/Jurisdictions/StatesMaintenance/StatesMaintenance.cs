using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.StatesMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    class StatesMaintenance : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainStates(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            new StatesMaintenanceDbSetUp().Prepare();
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction)
                       .Create();
            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);
            var pageDetails = new StatesMaintenanceDetailPage(driver);
            var topic = pageDetails.StatesTopic;
            var searchResults = new KendoGrid(driver, "searchResults");
            var popups = new CommonPopups(driver);

            #region Add States to a Jurisdiction
            topic.SearchTextBox(driver).Clear();
            topic.SearchTextBox(driver).SendKeys(StatesMaintenanceDbSetUp.CountryCode1);
            topic.SearchButton(driver).WithJs().Click();

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(StatesMaintenanceDbSetUp.CountryCode1, searchResults.CellText(0, 1), "Search returns record matching code");

            topic.BulkMenu(driver);
            topic.SelectPageOnly(driver);
            topic.EditButton(driver);
            topic.NavigateTo();
            topic.Add();
            topic.SaveButton(driver).ClickWithTimeout();
            Assert.True(popups.AlertModal.Modal.Displayed, "Mandatory field required.");
            popups.AlertModal.Ok();

            topic.NavigateTo();
            topic.Grid.ToggleDelete(0);
            topic.Add();
            topic.StateTextBox(driver).SendKeys("e2e");
            driver.WaitForAngularWithTimeout();
            topic.StateNameTextBox(driver).SendKeys("e2e Test");
            topic.SaveButton(driver).ClickWithTimeout();

            topic.NavigateTo();
            Assert.AreEqual(1, topic.GridRowsCount, "only deletes the row which was marked as deleted");
            Assert.AreEqual("e2e", topic.StateTextBox(driver).GetAttribute("value"), "Record matching State");
            Assert.AreEqual("e2e Test", topic.StateNameTextBox(driver).GetAttribute("value"), "Record matching State Name.");
            #endregion

            #region Edit States in Jurisdiction
            topic.NavigateTo();
            topic.StateNameTextBox(driver).Clear();
            topic.StateNameTextBox(driver).SendKeys("e2e Test edit");
            pageDetails.Save();

            topic.NavigateTo();
            Assert.AreEqual(1, topic.GridRowsCount, "only deletes the row which was marked as deleted");
            Assert.AreEqual("e2e Test edit", topic.StateNameTextBox(driver).GetAttribute("value"), "Record matching State Name.");
            #endregion

            #region Delete States in Jurisdiction
            topic.NavigateTo();
            topic.Grid.ToggleDelete(0);

            pageDetails.Save();
            Assert.AreEqual(0, topic.GridRowsCount, "only deletes the row which was marked as deleted");
            #endregion

            #region In Use Check
            topic.NavigateTo();
            topic.Add();
            topic.StateTextBox(driver).SendKeys("InUse");
            driver.WaitForAngularWithTimeout();
            topic.StateNameTextBox(driver).SendKeys("InUse State");
            topic.SaveButton(driver).ClickWithTimeout();

            topic.NavigateTo();
            topic.Grid.ToggleDelete(0);
            pageDetails.Save();
            Assert.IsNotNull(popups.AlertModal, "Alert modal is present");
            popups.AlertModal.Ok();
            Assert.AreEqual(1, topic.GridRowsCount, "No records deleted");
            #endregion
        }
    }
}
