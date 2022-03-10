using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class AngularKendoGrid : PageObject
    {
        readonly string _bulkMenuContext;
        readonly string _id;

        public AngularKendoGrid(NgWebDriver driver, string id) : base(driver)
        {
            _id = id;
        }

        public AngularKendoGrid(NgWebDriver driver, string id, string bulkMenuContext) : base(driver)
        {
            _id = id;
            _bulkMenuContext = bulkMenuContext;
        }
        
        public void ExpandRow(int rowNumber)
        {
            Cell(rowNumber, 0).FindElement(By.CssSelector("a")).ClickWithTimeout();
        }

        public bool HasExpandRow(int rowNumber)
        {
            return Cell(rowNumber, 0).FindElements(By.CssSelector("a")).Any();
        }

        public NgWebElement Grid => Driver.FindElement(By.Id(_id));

        public ReadOnlyCollection<NgWebElement> HeaderRows => Grid.FindElements(By.CssSelector($"[id^=\'{_id}\'] thead tr"));

        public ReadOnlyCollection<NgWebElement> HeaderColumns => HeaderRows.Single().FindElements(By.TagName("th"));

        public List<string> HeaderColumnsText => HeaderColumns.Select(_ => _.Text).ToList();

        /// <summary>
        ///     Returns distinct header fields that are defined. Skips the columns that dont have data-field attribute defined
        /// </summary>
        public List<string> HeaderColumnsFields => HeaderRows.Single().FindElements(By.CssSelector("th span[data-field]")).Select(_ => _.GetAttribute("data-field")).ToList();

        /// <summary>
        ///     If the data-field attribute is not defined, uses null value for that particular th. It maintains the order of
        ///     columns
        /// </summary>
        public List<string> HeaderColumnsFieldsOrdered => HeaderColumns.Select(_ => _.FindElements(By.TagName("span[data-field]"))
                                                                                     .FirstOrDefault()?
                                                                                     .GetAttribute("data-field")).ToList();

        public ReadOnlyCollection<NgWebElement> DoubleHeaderColumns => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] thead th[data-index]"));

        public ReadOnlyCollection<NgWebElement> Rows => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] >:not(.k-grid-norecords) tbody tr:not(.k-grid-norecords)"));

        public ReadOnlyCollection<NgWebElement> MasterRows => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] >:not(.k-grid-content-locked) tbody tr.k-master-row"));

        public ReadOnlyCollection<NgWebElement> DetailRows => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] >:not(.k-grid-content-locked) tbody tr.k-detail-row"));

        public ReadOnlyCollection<NgWebElement> LockedRows => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] .k-grid-content-locked tr[data-uid]"));

        public bool GridIsLoaded => Driver.WrappedDriver.ExecuteJavaScript<bool>($"return $(\"[id^=\'{_id}\'].k-grid.ip-data-loaded\").length == 1");

        public ReadOnlyCollection<NgWebElement> Headers => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] thead th"));

        public ActionMenu ActionMenu => new ActionMenu(Driver.FindElement(By.CssSelector($"[id^=\'{_id}\']")), _bulkMenuContext);

        public ReadOnlyCollection<NgWebElement> HiddenRows => Driver.FindElements(By.CssSelector($"[id^=\'{_id}\'] >:not(.k-grid-content-locked) tbody tr.k-master-row.hide-row"));

        public NgWebElement AddButton => Grid.FindElements(By.CssSelector("ipx-add-button button")).FirstOrDefault();

        public ReadOnlyCollection<NgWebElement> AttachmentIcons => Driver.FindElements(By.Name("paperclip"));

        public NgWebElement EditableRow(int index = 0)
        {
            return Grid.FindElements(By.CssSelector(".k-grid-edit-row"))[index];
        }

        public void Add()
        {
            AddButton.ClickWithTimeout();
        }

        public string[] PageSizes()
        {
            return new SelectElement(Grid.FindElement(By.CssSelector(".k-pager-sizes")).FindElement(By.TagName("select"))).Options.Select(_ => _.Text.Trim()).ToArray();
        }

        public void PageNext()
        {
            Grid.FindElement(By.CssSelector(".k-grid-pager .k-i-arrow-e")).Click();
        }

        public void PagePrev()
        {
            Grid.FindElement(By.CssSelector(".k-grid-pager .k-i-arrow-w")).Click();
        }

        public string CurrentPage()
        {
            return Grid.FindElement(By.CssSelector(".k-grid-pager .k-pager-numbers .k-state-selected"))?.Text;
        }

        public void SelectFirstPage()
        {
            Grid.FindElement(By.CssSelector("ul[class='k-pager-numbers k-reset'] a[aria-label='Page 1']"))?.Click();
        }

        public void SelectSecondPage()
        {
            Grid.FindElement(By.CssSelector("ul[class='k-pager-numbers k-reset'] a[aria-label='Page 2']"))?.Click();
        }

        public void ChangePageSize(int index)
        {
            new SelectElement(Grid.FindElement(By.CssSelector(".k-pager-sizes")).FindElement(By.TagName("select"))).SelectByIndex(index);
        }

        public NgWebElement Cell(int rowIndex, int colIndex)
        {
            return Rows[rowIndex].FindElements(By.CssSelector("td"))[colIndex];
        }

        public NgWebElement Cell(int rowIndex, string colName)
        {
            var colIndex = FindColByText(colName);
            return Cell(rowIndex, colIndex);
        }

        public int FindColByText(string colName)
        {
            var colIndex = HeaderRows.Count == 1
                ? HeaderColumns.ToList().FindIndex(_ => _.Text == colName)
                : DoubleHeaderColumns.ToList().FindIndex(_ => _.Text == colName);

            if (colIndex < 0)
            {
                throw new Exception("Cannot find column by name '" +
                                    colName +
                                    "'. Instead the following columns were found :[" +
                                    string.Join(", ", HeaderColumns.Select(x => x.Text)) +
                                    "].");
            }

            return colIndex;
        }

        public NgWebElement FindRow(string colName, string cellValue, out int rowIndex)
        {
            var colIndex = FindColByText(colName);
            return FindRow(colIndex, cellValue, out rowIndex);
        }

        public NgWebElement FindRow(int colIndex, string cellValue, out int rowIndex)
        {
            var rows = Rows;

            for (var i = 0; i < rows.Count; i++)
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

        public string CellText(int rowIndex, int colIndex, bool ignoreStaleRef = false)
        {
            const int maxTries = 3;
            var tries = 0;
            try
            {
                return Cell(rowIndex, colIndex).WithJs().GetInnerText();
            }
            catch (StaleElementReferenceException) when (tries++ < maxTries)
            {
                return Cell(rowIndex, colIndex).WithJs().GetInnerText();
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
            Rows[rowIndex].FindElement(By.TagName("td")).WithJs().Click();
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
            Rows[rowIndex].FindElement(By.CssSelector("ipx-checkbox label")).WithJs().Click();
            Driver.WaitForAngular();
        }

        public NgWebElement RowElement(int rowIndex, By selector)
        {
            return Rows[rowIndex].FindElement(selector);
        }

        public void SelectIpCheckbox(int rowIndex)
        {
            Rows[rowIndex].FindElement(By.CssSelector("ipx-checkbox label")).WithJs().Click();
        }

        public void ClickEdit(int row)
        {
            Rows[row].FindElement(By.CssSelector("ipx-icon-button[buttonicon='pencil-square-o']")).ClickWithTimeout();
        }

        public void ClickRevert(int row)
        {
            Rows[row].FindElement(By.CssSelector("ipx-icon-button[buttonicon='revert']")).ClickWithTimeout();
        }

        public void ClickDuplicate(int row)
        {
            Rows[row].FindElement(By.CssSelector("ipx-icon-button[buttonicon='files-o']")).ClickWithTimeout();
        }

        public void ClickDelete(int row)
        {
            Rows[row].FindElement(By.CssSelector("ipx-icon-button[buttonicon='trash']")).ClickWithTimeout();
        }

        public void ToggleDelete(int row)
        {
            Rows[row].FindElement(By.CssSelector("ip-kendo-toggle-delete-button button")).ClickWithTimeout();
        }

        public bool IsRowDeleteMode(int row)
        {
            return Rows[row].GetAttribute("class").IndexOf("deleted", StringComparison.Ordinal) > -1;
        }

        public string CellTextByBinding(int rowIndex, string bindingName)
        {
            var es = Driver.FindElements(By.CssSelector("[id^='" + _id + "'].k-grid"));
            var e = es.Last();
            var trs = e.FindElements(By.CssSelector("tbody[role=rowgroup] tr"));
            var tr = trs[rowIndex];
            return tr.FindElement(NgBy.Binding(bindingName)).Text;
        }

        public string[] ColumnValues(int colIndex, int numberOfRows = -1, bool forMasterRows = false)
        {
            var rowCount = forMasterRows ? MasterRows.Count : Rows.Count;
            var texts = new List<string>();
            for (var i = 0; i < rowCount; i++)
            {
                if (numberOfRows > -1 && i <= numberOfRows)
                {
                    texts.Add(forMasterRows ? MasterCell(i, colIndex).Text : CellText(i, colIndex, true));
                }
            }

            return texts.ToArray();
        }

        public bool ColumnContains(int colIndex, By by, int numberOfRows = -1)
        {
            for (var i = 0; i < Rows.Count; i++)
            {
                if (numberOfRows <= -1 || i > numberOfRows) continue;
                if (Cell(i, colIndex).FindElements(by).Any())
                {
                    return true;
                }
            }

            return false;
        }

        public NgWebElement ReturnFirstCellContaining(int colIndex, By by)
        {
            for (var i = 0; i < Rows.Count; i++)
            {
                if (Cell(i, colIndex).FindElements(by).Any())
                {
                    return Cell(i, colIndex).FindElements(by).First();
                }
            }

            return null;
        }

        public IEnumerable<string> ValuesInRow(int rowIndex)
        {
            for (var i = 0; i < HeaderColumns.Count; i++) yield return CellText(rowIndex, i, true);
        }

        public bool CellIsSelected(int rowIndex, int colIndex, bool withJs = false)
        {
            if (withJs)
            {
                return Cell(rowIndex, colIndex).FindElement(By.TagName("input")).Selected;
            }

            return Cell(rowIndex, colIndex).FindElement(By.TagName("input")).WithJs().IsChecked();
        }

        public NgWebElement HeaderColumn(int index)
        {
            return HeaderColumns.Count > index ? HeaderColumns[index] : null;
        }

        public void ToggleDetailsRow(int rowIndex)
        {
            MasterCell(rowIndex, 0).FindElement(By.CssSelector("a")).ClickWithTimeout();
        }

        public bool RowIsHighlighted(int rowIndex)
        {
            var row = Rows[rowIndex];
            return row.GetAttribute("class").Contains("selected");
        }

        public void OpenTaskMenuFor(int rowIndex)
        {
            MasterCell(rowIndex, 1).FindElement(By.TagName("ipx-icon-button")).Click();
        }

        public void OpenContexualTaskMenu(int rowIndex)
        {
            Rows[rowIndex].FindElement(By.Name("tasksMenu")).Click();
            Driver.WaitForAngularWithTimeout();
        }

        public void FilterColumnByName(string headerText)
        {
            Driver.FindElement(By.XPath("//span[contains(text(),'" + headerText + "')]/parent::*/kendo-grid-filter-menu/a")).Click();
        }

        public void FilterOption(string filterText)
        {
            filterText = filterText.Replace("'", "\'");
            Driver.FindElement(By.XPath("//label[contains(text(),'" + filterText + "')]")).Click();
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

    public static class AngularKendoGridExtension
    {
        public static NgWebElement EditButton(this AngularKendoGrid grid, int rowIndex)
        {
            return grid.Rows[rowIndex - 1].FindElement(By.CssSelector(".cpa-icon.cpa-icon-pencil-square-o.undefined"));
        }

        public static NgWebElement DeleteButton(this AngularKendoGrid grid, int rowIndex)
        {
            return grid.Rows[rowIndex - 1].FindElement(By.CssSelector(".cpa-icon.cpa-icon-trash.undefined"));
        }
    }
}