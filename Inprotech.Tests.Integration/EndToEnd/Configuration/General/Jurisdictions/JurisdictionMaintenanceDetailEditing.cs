using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class JurisdictionMaintenanceDetailEditing : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void UpdateJurisdiction(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var scenario = new Scenario().Prepare();

            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction)
                       .WithPermission(ApplicationTask.ViewJurisdiction)
                       .Create();

            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);

            var searchOptions = new SearchOptions(driver);
            var searchText = driver.FindElement(By.Id("search-options-criteria"));
            searchText.SendKeys("e2eCountry");
            searchOptions.SearchButton.ClickWithTimeout();

            var searchResults = new KendoGrid(driver, "searchResults");
            // view the first jurisdiction in the list
            var bulkMenu = new ActionMenu(driver, "jurisdictionMenu");
            searchResults.SelectIpCheckbox(0);
            bulkMenu.OpenOrClose();
            bulkMenu.Option("edit").Click();

            var pageDetails = new JurisdictionDetailPage(driver);

            driver.WaitForAngularWithTimeout();
            pageDetails.OverviewTopic.Notes(driver).SendKeys("test Notes");
            var postalName = pageDetails.OverviewTopic.PostalName(driver);
            postalName.Clear();
            postalName.SendKeys("test Postal Name");

            // Update Address Settings
            var addressSettingsTopic = pageDetails.AddressSettingsTopic;
            addressSettingsTopic.NavigateTo();
            addressSettingsTopic.StateLabel(driver).SendKeys("Test");
            addressSettingsTopic.PostCodeLabel(driver).SendKeys("Test");
            pageDetails.SaveButton.Click();
            var popups = new CommonPopups(driver);
            Assert.True(popups.AlertModal.Modal.Displayed, "Mandatory field required.");
            popups.AlertModal.Ok();
            var nameStylePicklist = new PickList(driver).ByName("nameStyle");
            var addressStylePicklist = new PickList(driver).ByName("addressStyle");
            var populateCityFromPostcodePicklist = new PickList(driver).ByName("populateCityFromPostCode");
            nameStylePicklist.EnterAndSelect("Surname First");
            addressStylePicklist.EnterAndSelect("City before PostCode - Full State");
            populateCityFromPostcodePicklist.EnterAndSelect("Part of the postcode");

            //update billing defaults topic elements
            pageDetails.DefaultsTopic.NavigateTo();
            var currencyPicklist = new PickList(driver).ByName("defaultCurrency");
            currencyPicklist.EnterAndSelect(scenario.Details.Currency.ToString());
            var isSelected = pageDetails.DefaultsTopic.TaxMandatoryCheckbox(driver).Selected;
            pageDetails.DefaultsTopic.TaxMandatoryCheckbox(driver).WithJs().Click();
            var defaultTaxRate = new DropDown(driver).ByName("defaultTaxRate");
            defaultTaxRate.Text = scenario.Details.TaxRate.ToString();

            // update business day topic elements
            pageDetails.BusinessDaysTopic.NavigateTo();
            var isSaturdaySelected = pageDetails.BusinessDaysTopic.DayOfWeekCheckbox(driver, "saturday").Selected;
            pageDetails.BusinessDaysTopic.DayOfWeekCheckbox(driver, "saturday").WithJs().Click();
            var isSundaySelected = pageDetails.BusinessDaysTopic.DayOfWeekCheckbox(driver, "sunday").Selected;
            pageDetails.BusinessDaysTopic.DayOfWeekCheckbox(driver, "sunday").WithJs().Click();

            pageDetails.SaveButton.ClickWithTimeout();
            pageDetails.LevelUp();
            driver.WaitForAngularWithTimeout();

            bulkMenu.OpenOrClose();
            bulkMenu.Option("edit").Click();

            driver.WaitForAngularWithTimeout();
            pageDetails = new JurisdictionDetailPage(driver);

            var notes = pageDetails.OverviewTopic.Notes(driver);
            Assert.AreEqual(notes.GetAttribute("value"), "test Notes",
                            "Ensure notes are correctly saved");

            postalName = pageDetails.OverviewTopic.PostalName(driver);
            Assert.AreEqual(postalName.GetAttribute("value"), "test Postal Name",
                            "Ensure postal name is correctly saved");

            addressSettingsTopic.NavigateTo();
            Assert.AreEqual(addressSettingsTopic.StateLabel(driver).GetAttribute("value"), "Test",
                            "Ensure correctly saved");
            Assert.AreEqual(addressSettingsTopic.PostCodeLabel(driver).GetAttribute("value"), "Test",
                            "Ensure correctly saved");
            Assert.AreEqual("Surname First", nameStylePicklist.GetText(), "Property Type added.");
            Assert.AreEqual("City before PostCode - Full State", addressStylePicklist.GetText(), "Property Type added.");
            Assert.AreEqual("Part of the postcode", populateCityFromPostcodePicklist.GetText(), "Property Type added.");

            //assert default billing topic elements
            pageDetails.DefaultsTopic.NavigateTo();

            Assert.AreEqual(scenario.Details.TaxRate.ToString(), defaultTaxRate.Text);
            if (isSelected)
            {
                Assert.False(pageDetails.DefaultsTopic.TaxMandatoryCheckbox(driver).Selected);
            }
            else
            {
                Assert.True(pageDetails.DefaultsTopic.TaxMandatoryCheckbox(driver).Selected);
            }

            if (isSaturdaySelected)
            {
                Assert.False(pageDetails.BusinessDaysTopic.DayOfWeekCheckbox(driver, "saturday").Selected);
            }
            else
            {
                Assert.True(pageDetails.BusinessDaysTopic.DayOfWeekCheckbox(driver, "saturday").Selected);
            }

            if (isSundaySelected)
            {
                Assert.False(pageDetails.BusinessDaysTopic.DayOfWeekCheckbox(driver, "sunday").Selected);
            }
            else
            {
                Assert.True(pageDetails.BusinessDaysTopic.DayOfWeekCheckbox(driver, "sunday").Selected);
            }
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AddAndDeleteJurisdiction(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            new Scenario().Prepare();

            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction)
                       .WithPermission(ApplicationTask.ViewJurisdiction)
                       .Create();

            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);

            driver.WaitForAngularWithTimeout();
            driver.FindElement(By.Id("jurisdiction-add-btn")).ClickWithTimeout();

            var newJurisdictionDialog = new NewJurisdictionModalDialog(driver);
            newJurisdictionDialog.Code.Input.SendKeys("VQ");
            newJurisdictionDialog.Name.Input.SendKeys("new Country");
            newJurisdictionDialog.Apply();

            driver.WaitForAngularWithTimeout();

            var detailsPage = new JurisdictionDetailPage(driver);

            Assert.AreEqual("VQ", detailsPage.OverviewTopic.Code(driver).Value(), "The correct Country Code is displayed.");
            Assert.AreEqual("new Country", detailsPage.OverviewTopic.Name(driver).Value(), "The correct Name is saved.");
            Assert.AreEqual("new Country", detailsPage.OverviewTopic.PostalName(driver).Value(), "The correct Postal Name is saved.");

            detailsPage.LevelUp();

            var searchOptions = new SearchOptions(driver);
            var searchText = driver.FindElement(By.Id("search-options-criteria"));
            searchText.SendKeys("VQ");
            searchOptions.SearchButton.ClickWithTimeout();
            var searchResults = new KendoGrid(driver, "searchResults");
            var bulkMenu = new ActionMenu(driver, "jurisdictionMenu");
            searchResults.SelectIpCheckbox(0);
            bulkMenu.OpenOrClose();
            bulkMenu.Option("delete").Click();
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            Assert.True(searchResults.Rows.Count == 0, "Expected record to have been deleted");

            driver.FindElement(By.Id("jurisdiction-add-btn")).ClickWithTimeout();
            newJurisdictionDialog = new NewJurisdictionModalDialog(driver);
            newJurisdictionDialog.Code.Input.SendKeys("VQ2");
            newJurisdictionDialog.Name.Input.SendKeys("new Country 2");
            newJurisdictionDialog.Apply();

            detailsPage = new JurisdictionDetailPage(driver);
            detailsPage.Delete();
            popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();

            searchOptions = new SearchOptions(driver);
            searchText = driver.FindElement(By.Id("search-options-criteria"));
            searchText.Clear();
            searchText.SendKeys("VQ2");
            searchOptions.SearchButton.ClickWithTimeout();
            searchResults = new KendoGrid(driver, "searchResults");

            Assert.True(searchResults.Rows.Count == 0, "Expected record to have been deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void UpdateJurisdictionCode(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            new Scenario().Prepare();

            var user = new Users()
                       .WithPermission(ApplicationTask.MaintainJurisdiction)
                       .WithPermission(ApplicationTask.ViewJurisdiction)
                       .Create();

            SignIn(driver, "/#/configuration/general/jurisdictions", user.Username, user.Password);
            var pageDetails = new JurisdictionDetailPage(driver);

            var searchOptions = new SearchOptions(driver);
            var searchText = driver.FindElement(By.Id("search-options-criteria"));
            searchText.SendKeys("e2c Country");
            searchOptions.SearchButton.ClickWithTimeout();

            var searchResults = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("e2c", searchResults.CellText(0, 1), "Search returns record matching code");
            var bulkMenu = new ActionMenu(driver, "jurisdictionMenu");
            searchResults.SelectIpCheckbox(0);
            bulkMenu.OpenOrClose();
            bulkMenu.Option("changeCode").Click();
            driver.WaitForAngularWithTimeout();

            var changeCode = driver.FindElement(By.Name("newJurisdictionCode")).FindElement(By.TagName("input"));
            changeCode.SendKeys("e3c");
            pageDetails.SaveButton.ClickWithTimeout();
            var popups = new CommonPopups(driver);
            popups.ConfirmModal.Proceed();
            driver.WaitForAngularWithTimeout();
            searchText.Clear();
            searchText.SendKeys("e2c Country");
            searchOptions.SearchButton.ClickWithTimeout();
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual("e3c", searchResults.CellText(0, 1), "Search returns record matching code");
        }
    }
}