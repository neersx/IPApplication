using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class KendoGrid : PageObject
    {
        readonly string _id;
        readonly string _bulkMenuContext;

        public KendoGrid(NgWebDriver driver, string id) : base(driver)
        {
            _id = id;
        }

        public KendoGrid(NgWebDriver driver, string id, string bulkMenuContext) : base(driver)
        {
            _id = id;
            _bulkMenuContext = bulkMenuContext;
        }

        public NgWebElement Grid => Driver.FindElement(By.Id(_id));

        public ReadOnlyCollection<NgWebElement> HeaderRows => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] thead tr"));

        public ReadOnlyCollection<NgWebElement> HeaderColumns => HeaderRows.Single().FindElements(By.TagName("th"));

        public ReadOnlyCollection<NgWebElement> DoubleHeaderColumns => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] thead th[data-index]"));

        public ReadOnlyCollection<NgWebElement> Rows => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] >:not(.k-grid-content-locked) tbody tr"));

        public ReadOnlyCollection<NgWebElement> MasterRows => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] >:not(.k-grid-content-locked) tbody tr.k-master-row"));

        public ReadOnlyCollection<NgWebElement> DetailRows => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] >:not(.k-grid-content-locked) tbody tr.k-detail-row"));

        public ReadOnlyCollection<NgWebElement> LockedRows => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] .k-grid-content-locked tr[data-uid]"));

        public bool GridIsLoaded => Driver.WrappedDriver.ExecuteJavaScript<bool>($"return $(\"[id^=\'{_id}\'].k-grid.ip-data-loaded\").length == 1");
        
        public ReadOnlyCollection<NgWebElement> Headers => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] thead th"));

        public ActionMenu ActionMenu => new ActionMenu(Driver.FindElement(By.CssSelector($"[id^=\'{_id}\']")), _bulkMenuContext);

        public void PageNext()
        {
            Grid.FindElement(By.CssSelector(".k-pager-nav span.k-i-arrow-60-right")).Click();
        }

        public void PagePrev()
        {
            Grid.FindElement(By.CssSelector(".k-pager-nav span.k-i-arrow-60-left")).Click();
        }

        public string CurrentPage()
        {
            return Grid.FindElement(By.CssSelector("div.k-grid-pager .k-pager-numbers .k-state-selected"))?.Text;
        }
        
        public void ChangePageSize(int index)
        {
            var dropDown = Driver.FindElement(By.CssSelector("[id^='" + _id + "'] div.k-grid-pager span.k-pager-sizes span.k-select"));
            dropDown.WithJs().ScrollIntoView();
            dropDown.Click();
            var options = Driver.FindElements(By.CssSelector("div.k-animation-container div.k-list-container div.k-list-scroller ul li"));
            options[index].Click();
        }

        public NgWebElement Cell(int rowIndex, int colIndex)
        {
            return Rows[rowIndex].FindElements(By.CssSelector("td"))[colIndex];
        }
        
        public NgWebElement Cell(int rowIndex, string colName)
        {
            var colIndex = FindColByName(colName);
            return Cell(rowIndex, colIndex);
        }

        public int FindColByName(string colName)
        {
            var colIndex = HeaderRows.Count == 1
                ? HeaderColumns.ToList().FindIndex(_ => _.Text == colName)
                : DoubleHeaderColumns.ToList().FindIndex(_ => _.Text == colName);

            if (colIndex < 0)
                throw new Exception("Cannot find column by name '" +
                                    colName +
                                    "'. Instead the following columns were found :[" +
                                    string.Join(", ", HeaderColumns.Select(x => x.Text)) +
                                    "].");
            return colIndex;
        }

        public NgWebElement FindRow(string colName, string cellValue, out int rowIndex)
        {
            var colIndex = FindColByName(colName);
            return FindRow(colIndex, cellValue, out rowIndex);
        }

        public NgWebElement FindRow(int colIndex, string cellValue, out int rowIndex)
        {
            var rows = Rows;

            for (int i = 0; i < rows.Count; i++)
            {
                var cell = Cell(i, colIndex);
                if (cell.Text == cellValue)
                {
                    rowIndex = i;
                    return rows[i];
                }
            }

            rowIndex = -1;
            return null;
        }

        public string CellText(int rowIndex, int colIndex, bool ignoreStaleRef = false, bool trim = true)
        {
            const int maxTries = 3;
            var tries = 0;
            try
            {
                return Cell(rowIndex, colIndex).WithJs().GetInnerText(trim);
            }
            catch (StaleElementReferenceException) when (tries++ < maxTries)
            {
                return Cell(rowIndex, colIndex).WithJs().GetInnerText(trim);
            }
            catch (StaleElementReferenceException) when (ignoreStaleRef)
            {
                // swallow.
                return string.Empty;
            }
        }

        public string CellText(int rowIndex, string colName, bool ignoreStaleRef = false)
        {
            const int maxTries = 3;
            var tries = 0;
            try
            {
                return Cell(rowIndex, colName).Text;
            }
            catch (StaleElementReferenceException) when (tries++ < maxTries)
            {
                return Cell(rowIndex, colName).Text;
            }
            catch (StaleElementReferenceException) when (ignoreStaleRef)
            {
                // swallow.
                return string.Empty;
            }
        }

        public void ClickRow(int rowIndex)
        {
            // https://bugzilla.mozilla.org/show_bug.cgi?id=1422272
            // Rows[0].Click causes issue for Firefox
            Rows[rowIndex].WithJs().Click();
        }

        public NgWebElement MasterCell(int rowIndex, int colIndex)
        {
            return MasterRows[rowIndex].FindElements(By.CssSelector("td"))[colIndex];
        }

        public string MasterCellText(int rowIndex, int colIndex)
        {
            return MasterCell(rowIndex, colIndex).Text;
        }

        public NgWebElement LockedCell(int rowIndex, int colIndex)
        {
            return LockedRows[rowIndex].FindElements(By.CssSelector("td"))[colIndex];
        }

        public string LockedCellText(int rowIndex, int colIndex)
        {
            return LockedCell(rowIndex, colIndex).Text;
        }

        public void SelectRow(int rowIndex)
        {
            Rows[rowIndex].FindElement(By.CssSelector("input[type=checkbox]")).WithJs().Click();
            Driver.WaitForAngular();
        }

        public NgWebElement RowElement(int rowIndex, By selector)
        {
            return Rows[rowIndex].FindElement(selector);
        }

        public void SelectIpCheckbox(int rowIndex, bool inLockedColumn = false)
        {
            if (inLockedColumn)
            {
                LockedRows[rowIndex].FindElement(By.CssSelector("ip-checkbox label")).WithJs().Click();
            }
            else
            {
                Rows[rowIndex].FindElement(By.CssSelector("ip-checkbox label")).WithJs().Click();
            }
        }   

        public void ClickEdit(int row) => this.Rows[row].FindElement(By.CssSelector("[button-icon='pencil-square-o']")).ClickWithTimeout();
        public void ClickIcon(int row) => this.Rows[row].FindElement(By.CssSelector("[button-icon='cpa-icon cpa-icon-items-o']")).ClickWithTimeout();
        public void ClickDelete(int row) => this.Rows[row].FindElement(By.CssSelector("div.grid-actions button[button-icon='trash']")).ClickWithTimeout();
        public void ToggleDelete(int row) => this.Rows[row].FindElement(By.CssSelector("ip-kendo-toggle-delete-button button")).ClickWithTimeout();

        public string CellTextByBinding(int rowIndex, string bindingName)
        {
            var es = Driver.FindElements(By.CssSelector("[id^='" + _id + "'].k-grid"));
            var e = es.Last();
            var trs = e.FindElements(By.CssSelector("tbody[role=rowgroup] tr"));
            var tr = trs[rowIndex];
            return tr.FindElement(NgBy.Binding(bindingName)).Text;
        }

        public string[] ColumnValues(int colIndex, int numberOfRows = -1)
        {
            var texts = new List<string>();
            for (var i = 0; i < Rows.Count; i++)
            {
                if (numberOfRows > -1 && i <= numberOfRows)
                    texts.Add(CellText(i, colIndex, true));
            }
            return texts.ToArray();
        }

        public bool ColumnContains(int colIndex, By by, int numberOfRows = -1)
        {
            for (var i = 0; i < Rows.Count; i++)
            {
                if (numberOfRows <= -1 || i > numberOfRows) continue;
                if (this.Cell(i, colIndex).FindElements(@by).Any())
                    return true;
            }
            return false;
        }

        public NgWebElement ReturnFirstCellContaining(int colIndex, By by)
        {
            for (var i = 0; i < Rows.Count; i++)
            {
                if (Cell(i, colIndex).FindElements(@by).Any())
                    return Cell(i, colIndex).FindElements(@by).First();
            }
            return null;
        }

        public IEnumerable<string> ValuesInRow(int rowIndex)
        {
            for (var i = 0; i < HeaderColumns.Count; i++)
            {
                yield return CellText(rowIndex, i, true);
            }
        }

        public bool CellIsSelected(int rowIndex, int colIndex, bool withJs = false)
        {
            if (withJs)
                return Cell(rowIndex, colIndex).FindElement(By.TagName("input")).Selected;

            return Cell(rowIndex, colIndex).FindElement(By.TagName("input")).WithJs().IsChecked();
        }

        public NgWebElement HeaderColumn(string column)
        {
            return HeaderColumns.First(_ => _.GetAttribute("data-field") == column);
        }

        public void ToggleDetailsRow(int rowIndex)
        {
            MasterCell(rowIndex, 0).FindElement(By.CssSelector("a")).WithJs().Click();
        }

        public bool RowIsHighlighted(int rowIndex)
        {
            var row = this.Rows[rowIndex];
            return row.GetAttribute("class").Contains("k-state-selected");
        }

        public void FilterColumnByName(string headerText)
        {
            Driver.FindElement(By.XPath("//span[contains(text(),'"+headerText+"')]/parent::*/kendo-grid-filter-menu/a")).Click();
        }

        public void FilterOption(string filterText)
        {
            Driver.FindElement(By.XPath("//label[contains(text(),'"+filterText+"')]")).Click();
        }
        public void DoFilter()
        {
            Driver.FindElement(By.XPath("//button[@type='submit']")).Click();
        }

        public void ClearFilter()
        {
            Driver.FindElement(By.XPath("//button[@type='reset']")).Click();
        }
    }
}