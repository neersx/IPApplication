using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Components.Picklist
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class PicklistComponent : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PicksMultipleItems(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/picklist");

            var page = new PicklistTestPage(driver);
            
            page.MultiPickPickList.OpenPickList();
            Assert.IsTrue(page.MultiPickPickList.ModalDisplayed);
            var selectAllCb = new Checkbox(driver, driver.FindElement(By.CssSelector(".modal-dialog"))).ByModel("vm.isSelectAll");
            Assert.IsTrue(selectAllCb.Element.Displayed);
            selectAllCb.Click();
            Assert.IsTrue(selectAllCb.IsChecked);

            var allCheckBoxes = driver.FindElements(By.CssSelector(".modal-dialog ip-kendo-grid table input[type='checkbox']"));
            Assert.IsTrue(allCheckBoxes.Count > 1);
            Assert.IsTrue(allCheckBoxes.All(c => c.IsChecked()));

            selectAllCb.Click();
            Assert.IsTrue(allCheckBoxes.All(c => !c.IsChecked()));

            var grid = new KendoGrid(driver, "picklistResults");
            var ids = new List<string>();
            ids.Add(SelectRow(grid, 0));
            ids.Add(SelectRow(grid, 2));
            ids.Add(SelectRow(grid, 4));
            
            driver.FindElement(By.CssSelector("div[data-role='pager'] a[data-page='2']")).Click();
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

            driver.FindElement(By.CssSelector("div[data-role='pager'] a[data-page='2']")).Click();
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

            SignIn(driver, "/#/deve2e/picklist");

            var page = new PicklistTestPage(driver);

            page.MultiPickPickList.OpenPickList();
            Assert.IsTrue(page.MultiPickPickList.ModalDisplayed);

            var grid = new KendoGrid(driver, "picklistResults");
            var ids = new List<string>();
            ids.Add(SelectRow(grid, 0));
            ids.Add(SelectRow(grid, 1));
            ids.Add(SelectRow(grid, 2));
            ids.Add(SelectRow(grid, 3));
            ids.Add(SelectRow(grid, 4));
            page.MultiPickPickList.Apply();

            page.MultiPickPickList.SendKeys(Keys.Backspace);
            var allTags = page.MultiPickPickList.Tags.ToArray();
            Assert.IsTrue(ids.All(id => allTags.Contains(id)));

            var selectedTag = page.MultiPickPickList.SelectedTag.ToArray();
            Assert.IsTrue(selectedTag.Length == 1);
            Assert.IsTrue(selectedTag[0].Equals(allTags[allTags.Length-1]));

            page.MultiPickPickList.SendKeys(Keys.Backspace);
            allTags = page.MultiPickPickList.Tags.ToArray();
            Assert.IsTrue(!allTags.Contains(selectedTag[0]));
            selectedTag = page.MultiPickPickList.SelectedTag.ToArray();
            Assert.IsTrue(selectedTag[0].Equals(allTags[allTags.Length - 1]));

            page.MultiPickPickList.SendKeys(Keys.Left);
            page.MultiPickPickList.SendKeys(Keys.Left);
            page.MultiPickPickList.SendKeys(Keys.Left);
            selectedTag = page.MultiPickPickList.SelectedTag.ToArray();
            Assert.IsTrue(selectedTag[0].Equals(allTags[0]));

            page.MultiPickPickList.SendKeys(Keys.Backspace);
            allTags = page.MultiPickPickList.Tags.ToArray();
            Assert.IsTrue(!allTags.Contains(selectedTag[0]));
            Assert.IsTrue(allTags.Length == 3);
            selectedTag = page.MultiPickPickList.SelectedTag.ToArray();
            Assert.IsTrue(selectedTag[0].Equals(allTags[0]));

            page.MultiPickPickList.SendKeys(Keys.Delete);
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

            SignIn(driver, "/#/deve2e/picklist");

            var page = new PicklistTestPage(driver);

            Assert.IsEmpty(driver.FindElement(By.Id("formResult")).Value());
            page.NumberTypePickList.SendKeys(Keys.Enter);
            Assert.AreEqual("pass", driver.FindElement(By.Id("formResult")).WithJs().GetValue(), "Enter Key submits form from pick list");
        }

        NgWebElement RowCheckBox(KendoGrid grid, int row)
        {
            return grid.Rows[row].FindElement(By.CssSelector("input[type='checkbox']"));
        }

        string SelectRow(KendoGrid grid, int row)
        {
            grid.SelectRow(row);
            return grid.Cell(row, 1).Text;
        }
    }

    public class PicklistValidation : IntegrationTest
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

            SignIn(driver, "/#/deve2e/picklist");

            var page = new PicklistTestPage(driver);

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
    public class PicklistPaging : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void Paging(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/deve2e/picklist");

            driver.Manage().Window.Maximize();

            var page = new PicklistTestPage(driver);
            page.MultiPickPickList.OpenPickList();
            
            var pageList = driver.FindElement(By.CssSelector(".k-dropdown"));
            pageList.WithJs().ScrollIntoView();
            pageList.WithJs().Click();

            page.PagerList.First().WithJs().Click();
            Assert.AreEqual(5, page.MultiPickPickList.SearchGrid.Rows.Count, "Expected 5 items to be displayed");
            var pagerLabel = driver.FindElement(By.CssSelector("#picklistResults .k-pager-info"));
            Assert.IsTrue(pagerLabel.Text.StartsWith("1 - 5"), "Label is not as expected after changing to 5 per page");

            pageList.WithJs().ScrollIntoView();
            pageList.Click();

            var pageSizes = page.PagerList.Select(_ => _.Text);
            Assert.AreEqual(new[] { "5", "10", "15", "20" }, pageSizes.ToArray());

            page.PagerList.ElementAt(1).WithJs().Click();
            Assert.AreEqual(10, page.MultiPickPickList.SearchGrid.Rows.Count, "Expected 10 items to be displayed");

            if (browserType != BrowserType.FireFox) // weird issue with FF not getting updated inner text
            {
                pageList.WithJs().ScrollIntoView();
                pagerLabel = driver.FindElement(By.CssSelector("#picklistResults .k-pager-info"));
                var pagerInfoText = pagerLabel.WithJs().GetInnerText() ?? pagerLabel.Text;
                Assert.IsTrue(pagerInfoText.StartsWith("1 - 10"), "Label is not as expected after changing to 10 per page");
            }

            pageList.WithJs().ScrollIntoView();
            pageList.Click();
            page.PagerList.First().WithJs().Click();

            Assert.AreEqual(5, page.MultiPickPickList.SearchGrid.Rows.Count, "Expected only 5 items to be displayed");
            pagerLabel = driver.FindElement(By.CssSelector("#picklistResults .k-pager-info"));
            Assert.IsTrue(pagerLabel.Text.StartsWith("1 - 5"), "Label is not as expected after reverting to 5 per page");

            page.MultiPickPickList.Close();
            page.MultiPickPickList.OpenPickList();
            pagerLabel = driver.FindElement(By.CssSelector("#picklistResults .k-pager-info"));
            Assert.AreEqual(5, page.MultiPickPickList.SearchGrid.Rows.Count, "Expected only 5 items to be displayed");
            Assert.IsTrue(pagerLabel.Text.StartsWith("1 - 5"), "Label is not as expected after reload");
        }
    }

    internal class PicklistTestPage : PageObject
    {
        public PicklistTestPage(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            MultiPickPickList = new PickList(driver).ById("multipickPicklist");
        }

        public PickList MultiPickPickList;
        public string MultiPickData => Driver.FindElement(By.Id("multipickPicklist_data")).WithJs().GetInnerText();

        public IEnumerable<NgWebElement> PagerList => Driver.FindElement(By.CssSelector(".k-list-container .k-list")).FindElements(By.CssSelector("li.k-item"));

        public PickList CaseTypePickList => new PickList(Driver).ByName("caseType");
        public PickList JurisdictionPickList => new PickList(Driver).ByName("jurisdiction");
        public PickList PropertyTypePickList => new PickList(Driver).ByName("propertyType");

        public PickList NumberTypePickList => new PickList(Driver).ByName("numberType");
    }
}