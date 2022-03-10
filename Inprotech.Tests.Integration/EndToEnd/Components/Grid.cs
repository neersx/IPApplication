using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Components
{

    [Category(Categories.E2E)]
    [TestFixture]
    public class Grid : IntegrationTest
    {
        [TestCase(BrowserType.Chrome, Ignore = "Fixing in DR-47474")]
        [TestCase(BrowserType.Ie, Ignore = "Fixing in DR-47474")]
        [TestCase(BrowserType.FireFox, Ignore = "This is determined to be breaking on local")]
        public void MultiPageBulkAction(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/grid");

            var page = new GridTestPage(driver);

            page.ActionMenu.OpenOrClose();
            page.ActionMenu.SelectPage();
            Assert.IsFalse(page.ActionMenu.Option("action").Disabled());
            page.ActionMenu.CloseMenu();
            Assert.AreEqual(10, page.ActionMenu.SelectedItems(), "Bulk menu badge indicates number of selected items");
            
            page.ActionMenu.OpenOrClose();
            page.ActionMenu.SelectPage();
            //Assert.IsTrue(page.ActionMenu.Option("action").WithJs().HasClass("disabled"));
            page.ActionMenu.CloseMenu();
            Assert.AreEqual(0, page.ActionMenu.SelectedItems(), "Bulk menu badge indicates number of selected items");

            page.PagableGrid.SelectRow(0);
            page.PagableGrid.SelectRow(2);
            page.PagableGrid.SelectRow(5);
            Assert.AreEqual(3, page.ActionMenu.SelectedItems(), "Bulk menu badge indicates number of selected items");

            page.PagableGrid.PageNext();
            Assert.AreEqual(3, page.ActionMenu.SelectedItems(), "Bulk menu badge remembers selections from previous page");
            page.PagableGrid.SelectRow(0);
            page.PagableGrid.SelectRow(3);
            Assert.AreEqual(5, page.ActionMenu.SelectedItems(), "Bulk menu badge indicates number of selected items");

            page.PagableGrid.PagePrev();
            Assert.AreEqual(5, page.ActionMenu.SelectedItems(), "Bulk menu badge remembers selections from previous page");
            
            Assert.IsTrue(page.PagableGrid.CellIsSelected(0, 0), "First row remains selected after paging");
            Assert.IsTrue(page.PagableGrid.CellIsSelected(2, 0), "Second row remains selected after paging");
            Assert.IsTrue(page.PagableGrid.CellIsSelected(5, 0), "Fifth row remains selected after paging");

            page.ActionMenu.OpenOrClose();
            page.ActionMenu.Option("action").Click();
            page.ActionMenu.CloseMenu();
            Assert.AreEqual("0,2,5,10,13", page.SelectedItemResult, "Selected items across pages are accessible by menu action");

            page.ActionMenu.OpenOrClose();
            page.ActionMenu.ClearAll();
            page.ActionMenu.CloseMenu();
            Assert.AreEqual(0, page.ActionMenu.SelectedItems(), "Clear all should clear all times across pages");
            Assert.IsFalse(page.PagableGrid.CellIsSelected(0, 0, true), "Row is unselected after clear all");
            Assert.IsFalse(page.PagableGrid.CellIsSelected(2, 0), "Second row is unselected after clear all");
            Assert.IsFalse(page.PagableGrid.CellIsSelected(5, 0), "Fifth row is unselected after clear all");
        }
    }

    public class GridTestPage : PageObject
    {
        const string GridId = "pagableGridTest";
        const string GridActionContext = "pagableGridTest";

        public GridTestPage(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            PagableGrid = new KendoGrid(driver, GridId, GridActionContext);
        }

        public KendoGrid PagableGrid { get; }
        public ActionMenu ActionMenu => PagableGrid.ActionMenu;
        public string SelectedItemResult => Driver.FindElement(By.Id("selectedItemsResult")).Value();
    }
}
