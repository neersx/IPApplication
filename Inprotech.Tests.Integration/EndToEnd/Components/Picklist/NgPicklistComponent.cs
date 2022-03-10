using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Components.Picklist
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class NgPicklistComponent : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PicksMultipleItems(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/ipx-picklist");

            var page = new NgPicklistTestPage(driver);

            page.MultiPickPickList.OpenPickList();
            Assert.IsTrue(page.MultiPickPickList.ModalDisplayed);

            // TODO select all
            //var selectAllCb = new Checkbox(driver, driver.FindElement(By.CssSelector(".modal-dialog"))).ByModel("vm.isSelectAll");
            //Assert.IsTrue(selectAllCb.Element.Displayed);
            //selectAllCb.Click();
            //Assert.IsTrue(selectAllCb.IsChecked);

            //var allCheckBoxes = driver.FindElements(By.CssSelector(".modal-dialog ip-kendo-grid table input[type='checkbox']"));
            //Assert.IsTrue(allCheckBoxes.Count > 1);
            //Assert.IsTrue(allCheckBoxes.All(c => c.IsChecked()));

            //selectAllCb.Click();
            //Assert.IsTrue(allCheckBoxes.All(c => !c.IsChecked()));

            var grid = new AngularKendoGrid(driver, "picklistResults");
            var ids = new List<string>
            {
                SelectRow(grid, 0),
                SelectRow(grid, 2),
                SelectRow(grid, 4)
            };

            driver.FindElement(By.CssSelector("kendo-pager a[aria-label='Page 2']")).Click();
            ids.Add(SelectRow(grid, 3));
            ids.Add(SelectRow(grid, 4));

            page.MultiPickPickList.Apply();

            var allTags = page.MultiPickPickList.Tags.ToArray();
            Assert.IsTrue(ids.All(id => allTags.Contains(id)));
            page.MultiPickPickList.OpenPickList();

            Assert.IsTrue(RowCheckBox(grid, 0).IsChecked());
            Assert.IsFalse(RowCheckBox(grid, 1).IsChecked());
            Assert.IsTrue(RowCheckBox(grid, 2).IsChecked());
            Assert.IsFalse(RowCheckBox(grid, 3).IsChecked());
            Assert.IsTrue(RowCheckBox(grid, 4).IsChecked());
            // untick one
            grid.SelectRow(2);
            Assert.IsFalse(grid.Rows[2].FindElement(By.CssSelector("input[type='checkbox']")).IsChecked());

            var removedId1 = grid.CellText(2, 1);
            ids.Remove(removedId1);

            driver.FindElement(By.CssSelector("kendo-pager a[aria-label='Page 2']")).Click();
            Assert.IsFalse(RowCheckBox(grid, 0).IsChecked());
            Assert.IsFalse(RowCheckBox(grid, 1).IsChecked());
            Assert.IsFalse(RowCheckBox(grid, 2).IsChecked());
            Assert.IsTrue(RowCheckBox(grid, 3).IsChecked());
            Assert.IsTrue(RowCheckBox(grid, 4).IsChecked());
            grid.SelectRow(3);
            var removedId2 = grid.CellText(3, 1);
            ids.Remove(removedId2);

            page.MultiPickPickList.Apply();

            allTags = page.MultiPickPickList.Tags.ToArray();
            Assert.IsTrue(ids.All(id => allTags.Contains(id)));
            Assert.IsFalse(allTags.Contains(removedId1));
            Assert.IsFalse(allTags.Contains(removedId2));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PicksMultipleItemsNavigation(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/ipx-picklist");

            var page = new NgPicklistTestPage(driver);

            page.MultiPickPickList.OpenPickList();
            Assert.IsTrue(page.MultiPickPickList.ModalDisplayed);

            var grid = new AngularKendoGrid(driver, "picklistResults");
            var ids = new List<string>
            {
                SelectRow(grid, 0),
                SelectRow(grid, 1),
                SelectRow(grid, 2),
                SelectRow(grid, 3),
                SelectRow(grid, 4)
            };
            page.MultiPickPickList.Apply();

            page.MultiPickPickList.SendKeys(Keys.Backspace);
            driver.WaitForAngularWithTimeout();
            var allTags = page.MultiPickPickList.Tags.ToArray();
            Assert.IsTrue(ids.All(id => allTags.Contains(id)));

            var selectedTag = page.MultiPickPickList.SelectedTag.ToArray();
            Assert.IsTrue(selectedTag.Length == 1);
            Assert.IsTrue(selectedTag[0].Equals(allTags[allTags.Length - 1]));

            page.MultiPickPickList.SendKeys(Keys.Backspace);
            driver.WaitForAngularWithTimeout();
            allTags = page.MultiPickPickList.Tags.ToArray();
            Assert.IsTrue(!allTags.Contains(selectedTag[0]));
            selectedTag = page.MultiPickPickList.SelectedTag.ToArray();
            Assert.IsTrue(selectedTag[0].Equals(allTags[allTags.Length - 1]));

            page.MultiPickPickList.SendKeys(Keys.Left);
            driver.WaitForAngularWithTimeout();
            page.MultiPickPickList.SendKeys(Keys.Left);
            driver.WaitForAngularWithTimeout();
            page.MultiPickPickList.SendKeys(Keys.Left);
            driver.WaitForAngularWithTimeout();
            selectedTag = page.MultiPickPickList.SelectedTag.ToArray();
            Assert.IsTrue(selectedTag[0].Equals(allTags[0]));

            page.MultiPickPickList.SendKeys(Keys.Backspace);
            driver.WaitForAngularWithTimeout();
            allTags = page.MultiPickPickList.Tags.ToArray();
            Assert.IsTrue(!allTags.Contains(selectedTag[0]));
            Assert.IsTrue(allTags.Length == 3);
            selectedTag = page.MultiPickPickList.SelectedTag.ToArray();
            Assert.IsTrue(selectedTag[0].Equals(allTags[0]));

            page.MultiPickPickList.SendKeys(Keys.Delete);
            driver.WaitForAngularWithTimeout();
            allTags = page.MultiPickPickList.Tags.ToArray();
            Assert.IsTrue(!allTags.Contains(selectedTag[0]));
            Assert.IsTrue(allTags.Length == 2);
            selectedTag = page.MultiPickPickList.SelectedTag.ToArray();
            Assert.IsTrue(selectedTag[0].Equals(allTags[0]));
        }

        // This test doesn't work in IE, but works when performed manually
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void FormSubmissionFromKeypress(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/ipx-picklist");

            var page = new NgPicklistTestPage(driver);

            Assert.IsEmpty(driver.FindElement(By.Id("formResult")).Value());
            page.NumberTypePickList.SendKeys(Keys.Enter);
            Assert.AreEqual("PASS", driver.FindElement(By.Id("formResult")).WithJs().GetValue(), "Enter Key submits form from pick list");
        }

        NgWebElement RowCheckBox(AngularKendoGrid grid, int row)
        {
            return grid.Rows[row].FindElement(By.CssSelector("input[type='checkbox']"));
        }

        string SelectRow(AngularKendoGrid grid, int row)
        {
            grid.SelectRow(row);
            return grid.Cell(row, 1).Text;
        }
    }

    public class NgPicklistValidation : IntegrationTest
    {
        internal const string InvalidCaseTypeDescription = "e2e - invalid case type";
        internal const string InvalidJurisdictionDescription = "e2e - invalid jurisdiction";
        internal const string InvalidPropertyTypeDescription = "e2e - invalid property type";

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PicklistDataEntry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            PickListFixture data;
            using (var setup = new PicklistDbSetup())
            {
                data = setup.Setup();
            }

            SignIn(driver, "/#/deve2e/ipx-picklist");

            var page = new NgPicklistTestPage(driver);

            page.CaseTypePickList.SendKeys(InvalidCaseTypeDescription);
            page.JurisdictionPickList.SendKeys(InvalidJurisdictionDescription);
            page.PropertyTypePickList.SendKeys(InvalidPropertyTypeDescription).Blur();

            Assert.IsTrue(page.CaseTypePickList.HasError, "Case Type Pick list shows error when invalid entry entered");
            Assert.IsTrue(page.JurisdictionPickList.HasError, "Jurisdiction Pick list shows error when invalid entry entered");
            Assert.IsTrue(page.PropertyTypePickList.HasError, "Property Type Pick list shows error when invalid entry entered");

            page.CaseTypePickList.Typeahead.Clear();
            page.JurisdictionPickList.Typeahead.Clear();
            page.PropertyTypePickList.Typeahead.Clear();

            Assert.IsFalse(page.CaseTypePickList.HasError, "Case Type Pick list does not show error when empty");
            Assert.IsFalse(page.JurisdictionPickList.HasError, "Jurisdiction Pick list does not show error when empty");
            Assert.IsFalse(page.PropertyTypePickList.HasError, "Property Type Pick list does not show error when empty");

            page.PropertyTypePickList.SendKeys(data.PropertyType).Blur();
            Assert.IsFalse(page.PropertyTypePickList.HasError, "Property Type Pick List shows no error when valid entry is entered");
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class NgPicklistPaging : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void Paging(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/ipx-picklist");

            driver.Manage().Window.Maximize();

            var page = new NgPicklistTestPage(driver);
            page.MultiPickPickList.OpenPickList();
            var grid = new AngularKendoGrid(driver, "picklistResults");

            var pageListSection = driver.FindElement(By.CssSelector(".k-pager-sizes"));
            pageListSection.WithJs().ScrollIntoView();

            grid.ChangePageSize(0);

            Assert.AreEqual(5, grid.Rows.Count, "Expected 5 items to be displayed");
            var pagerLabel = driver.FindElement(By.CssSelector("#picklistResults .k-pager-info"));
            Assert.IsTrue(pagerLabel.Text.StartsWith("1 - 5"), "Label is not as expected after changing to 5 per page");

            pageListSection.WithJs().ScrollIntoView();

            var pageSizes = grid.PageSizes();

            Assert.AreEqual(new[] { "5", "10", "15", "20" }, pageSizes.ToArray());

            grid.ChangePageSize(1);
            Assert.AreEqual(10, grid.Rows.Count, "Expected 10 items to be displayed");

            if (browserType != BrowserType.FireFox) // weird issue with FF not getting updated inner text
            {
                pageListSection.WithJs().ScrollIntoView();
                pagerLabel = driver.FindElement(By.CssSelector("#picklistResults .k-pager-info"));
                var pagerInfoText = pagerLabel.WithJs().GetInnerText() ?? pagerLabel.Text;
                Assert.IsTrue(pagerInfoText.StartsWith("1 - 10"), "Label is not as expected after changing to 10 per page");
            }

            pageListSection.WithJs().ScrollIntoView();
            grid.ChangePageSize(0);

            Assert.AreEqual(5, grid.Rows.Count, "Expected only 5 items to be displayed");
            pagerLabel = driver.FindElement(By.CssSelector("#picklistResults .k-pager-info"));
            Assert.IsTrue(pagerLabel.Text.StartsWith("1 - 5"), "Label is not as expected after reverting to 5 per page");

            page.MultiPickPickList.Close();
            page.MultiPickPickList.OpenPickList();
            pagerLabel = driver.FindElement(By.CssSelector("#picklistResults .k-pager-info"));
            Assert.AreEqual(5, page.MultiPickPickList.SearchGrid.Rows.Count, "Expected only 5 items to be displayed");
            Assert.IsTrue(pagerLabel.Text.StartsWith("1 - 5"), "Label is not as expected after reload");
        }
    }

    internal class NgPicklistTestPage : PageObject
    {
        public NgPicklistTestPage(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            MultiPickPickList = new AngularPicklist(driver).ById("multipickPicklist");
        }

        public AngularPicklist MultiPickPickList;
        public string MultiPickData => Driver.FindElement(By.Id("multipickPicklist_data")).WithJs().GetInnerText();

        public IEnumerable<NgWebElement> PagerList => Driver.FindElement(By.CssSelector(".k-list-container .k-list")).FindElements(By.CssSelector("li.k-item"));

        public AngularPicklist CaseTypePickList => new AngularPicklist(Driver).ByName("caseType");
        public AngularPicklist JurisdictionPickList => new AngularPicklist(Driver).ByName("jurisdiction");
        public AngularPicklist PropertyTypePickList => new AngularPicklist(Driver).ByName("propertyType");

        public AngularPicklist NumberTypePickList => new AngularPicklist(Driver).ByName("numberType");
    }
}