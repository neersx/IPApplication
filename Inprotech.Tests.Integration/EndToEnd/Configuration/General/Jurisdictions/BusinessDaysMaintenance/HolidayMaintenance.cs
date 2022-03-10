using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.BusinessDaysMaintenance
{
    [Category(Categories.E2E)]
    [TestFixture]
    class HolidayMaintenance : IntegrationTest
    {

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void MaintainHolidays(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction)
                       .Create();
            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);
            var pageDetails = new JurisdictionDetailPage(driver);
            var topic = pageDetails.BusinessDaysTopic;
            var searchResults = new KendoGrid(driver, "searchResults");
            
            var scenario = new HolidayMaintenanceDbSetUp().Prepare();
            var popups = new CommonPopups(driver);

            topic.SearchTextBox(driver).Clear();
            topic.SearchTextBox(driver).SendKeys(scenario.CountryCode);
            topic.SearchButton(driver).WithJs().Click();

            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(scenario.CountryCode, searchResults.CellText(0, 1), "Search returns record matching code");

            topic.BulkMenu(driver);
            topic.SelectPageOnly(driver);
            topic.EditButton(driver);
            topic.NavigateTo();

            topic.AddButton().Click();
            topic.HolidayDatePicker(driver).SendKeys(scenario.CountryHolidayToBeAdded.HolidayDate.ToShortDateString());
            topic.HolidayNameTextBox(driver).SendKeys(scenario.CountryHolidayToBeAdded.HolidayName);
            topic.SaveButton(driver).ClickWithTimeout();
            
            topic.NavigateTo();
            Assert.AreEqual(1, topic.GridRowsCount, "only one record returned");
            Assert.AreEqual(scenario.CountryHolidayToBeAdded.HolidayDate.ToString("dd-MMM-yyyy"), topic.HolidayGrid.CellText(0, 1), "Ensure the date is Same");
            Assert.AreEqual(scenario.CountryHolidayToBeAdded.HolidayName, topic.HolidayGrid.CellText(0, 3), "Ensure the holiday is Same");

            topic.HolidayBulkMenu(driver);
            topic.HolidayBulkmenuSelectPageOnly(driver);
            topic.HolidayBulkmenuEditButton(driver);
            topic.HolidayNameTextBox(driver).Clear();
            topic.HolidayNameTextBox(driver).SendKeys(scenario.UpdatedHolidayName);
            topic.SaveButton(driver).ClickWithTimeout();
            topic.DiscardButton(driver).ClickWithTimeout();

            topic.NavigateTo();
            Assert.AreEqual(1, topic.GridRowsCount, "only one record returned");
            Assert.AreEqual(scenario.CountryHolidayToBeAdded.HolidayDate.ToString("dd-MMM-yyyy"), topic.HolidayGrid.CellText(0, 1), "Ensure the date is Same");
            Assert.AreEqual(scenario.UpdatedHolidayName, topic.HolidayGrid.CellText(0, 3), "Ensure the updated holiday is Same");
            
            topic.HolidayBulkMenu(driver);
            topic.HolidayBulkmenuSelectPageOnly(driver);
            topic.HolidayBulkMenuClickOnDelete(driver);
            popups.ConfirmModal.Yes().ClickWithTimeout();
            Assert.AreEqual(0, topic.GridRowsCount, "No record returned");
        }
    }
}
