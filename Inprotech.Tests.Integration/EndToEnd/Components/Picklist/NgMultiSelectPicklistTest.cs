using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Components.Picklist
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class NgMultiSelectPicklistTest : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SelectAllCheckboxInMultiPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/case/search");
            driver.Manage().Window.Maximize();
            var page = new NgPicklistTestPage(driver);
            page.JurisdictionPickList.OpenPickList();
            Assert.IsTrue(page.MultiPickPickList.ModalDisplayed);
            var selectAllCb = new AngularCheckbox(driver).ByName("chkSelectAll");
            selectAllCb.Click();
            Assert.IsTrue(selectAllCb.IsChecked);

            var grid = new AngularKendoGrid(driver, "picklistResults");

            Assert.IsTrue(grid.CellIsSelected(0, 0));
            Assert.IsTrue(grid.CellIsSelected(2, 0));
            grid.SelectSecondPage();
            driver.WaitForAngularWithTimeout();
            Assert.IsFalse(selectAllCb.IsChecked);
            selectAllCb.Click();
            Assert.IsTrue(selectAllCb.IsChecked);
            grid.SelectFirstPage();
            driver.WaitForAngularWithTimeout();
            Assert.IsTrue(selectAllCb.IsChecked);
            
            grid.SelectRow(2);
            Assert.IsFalse(grid.CellIsSelected(2,0));
            Assert.IsFalse(selectAllCb.IsChecked);
        }
    }
}