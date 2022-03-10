using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.FileLocationOffice
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class Offices : IntegrationTest
    {
        FileLocationOfficeDbSetup _dbSetup;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void FileLocationOfficesList(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainFileLocationOffice).Create();
            var driver = BrowserProvider.Get(browserType);
            _dbSetup = new FileLocationOfficeDbSetup();
            var data = _dbSetup.SetupOffices();
            SignIn(driver, "/#/configuration/search", user.Username, user.Password);
            var page = new FileLocationOfficePageObject(driver);
            page.SearchTextBox(driver).SendKeys("Office File Locations");
            page.SearchButton.ClickWithTimeout();
            page.FileLocationOfficeNavigationLink.ClickWithTimeout();
            driver.WaitForAngular();

            Assert.True(page.FileLocationOfficeGrid.Rows.Count >= 2);
            var f1 = (TableCode)data.f1;
            Assert.AreEqual(f1.Name, page.FileLocationOfficeGrid.CellText(0, 0));
            var firstRow = new EditFileLocationOfficeRow(driver, page.FileLocationOfficeGrid.Rows[0]);
            Assert.AreEqual(((Office)data.o1).Name, firstRow.Office.GetText(), "Shows the correct office");
            firstRow.Office.Typeahead.Clear();
            firstRow.Office.Typeahead.Click();
            firstRow.Office.SendKeys(((Office) data.o2).Name);
            firstRow.Office.SendKeys(Keys.ArrowDown);
            firstRow.Office.SendKeys(Keys.ArrowDown);
            firstRow.Office.SendKeys(Keys.Tab);
            driver.WaitForAngular();
            Assert.True(page.SaveButton.Enabled);
            Assert.True(page.RevertButton.Enabled);
            page.RevertButton.ClickWithTimeout();
            var popup = new CommonPopups(driver);
            popup.DiscardChangesModal.Discard();
            driver.WaitForAngular();
            firstRow = new EditFileLocationOfficeRow(driver, page.FileLocationOfficeGrid.Rows[0]);
            Assert.AreEqual(((Office)data.o1).Name, firstRow.Office.GetText(), "Shows the correct office");

            var secondRow = new EditFileLocationOfficeRow(driver, page.FileLocationOfficeGrid.Rows[1]);
            secondRow.Office.Clear();
            secondRow.Office.SendKeys(((Office) data.o2).Name);
            page.SaveButton.Click();
            driver.WaitForAngularWithTimeout();
            popup.WaitForFlashAlert();
            Assert.True(page.SaveButton.IsDisabled());
        }
    }
}
