using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    class AngularGridFilter : PageObject
    {
        protected readonly int Col;
        protected readonly string Grid;
        protected readonly string ID;

        public AngularGridFilter (NgWebDriver driver, string grid, int col) : base(driver)
        {
            ID = '#' + grid + "_filter_" + col;
            Col = col;
            Grid = grid;
        }

        public NgWebElement FindElement() => Driver.FindElements(By.CssSelector("#" + Grid + " th"))[Col];
        public NgWebElement FindFilterMenu() => Driver.FindElement(By.CssSelector("kendo-grid-filter-menu-container"));
        public NgWebElement FilterButton()
        {
            return FindElement().FindElement(By.CssSelector(".k-grid-filter"));
        }
        
        public void Open(bool waitForBlockUi = false)
        {
            if (waitForBlockUi) Driver.WaitForBlockUi();
            
            // filter opens, loads contents then resizes
            // resizing may leave some of the elements out of scroll view
            // before opening, scroll down a bit if filter is too close to the bottom of the page
            var filterButton = FilterButton();

            // the grid itself may be scrollable
            // make sure that filter button is inside the view

            try
            {
                var gridScroll = Driver.FindElements(By.CssSelector("#" + Grid + " .k-grid-content")).FirstOrDefault();

                if (gridScroll != null)
                {
                    var gridLeft = gridScroll.WithJs().ScrollLeft();
                    var toScrollX = filterButton.Location.X - gridScroll.Location.X - gridScroll.Size.Width + 200;
                    if (toScrollX > 0) gridScroll.WithJs().ScrollLeft(gridLeft + toScrollX);
                }
            }
            catch
            {
            }

            filterButton.WithJs().ScrollIntoView();
            filterButton.ClickWithTimeout();
        }
        
        public void Dismiss()
        {
            var filterButton = FilterButton();

            filterButton.WithJs().ScrollIntoView();

            filterButton.ClickWithTimeout();
        }

        public void Filter()
        {
            FindFilterMenu().FindElement(By.CssSelector("button[type=submit]")).WithJs().Click();
            Driver.WaitForGridLoader();
            Driver.WaitForAngular();
        }

        public void Clear()
        {
            var selector = "button[type=reset]";
            FindFilterMenu().FindElement(By.CssSelector(selector)).WithJs().Click();
            Driver.WaitForGridLoader();
            Driver.WaitForAngularWithTimeout();
        }
    }
    class AngularMultiSelectGridFilter : AngularGridFilter
    {
        public AngularMultiSelectGridFilter(NgWebDriver driver, string grid, int col) : base(driver, grid, col)
        {
        }
        public int ItemCount => FindFilterMenu().FindElements(By.CssSelector("kendo-grid-filter-menu-container ul.k-multicheck-wrap li:not([style='display: none;']) input:not([id='chk-SelectAll'])")).Count;

        public int CheckedItemCount => Driver.FindElements(By.CssSelector("kendo-grid-filter-menu-container ul.k-multicheck-wrap input:checked:not(.k-check-all)")).Count;

        public String[] SelectedValues => Driver.FindElements(By.CssSelector("kendo-grid-filter-menu-container ul.k-multicheck-wrap input:checked:not(.k-check-all)")).Select(e => e.Value()).ToArray();

        public void SelectAll()
        {
            Driver.FindElement(By.CssSelector(ID + " .k-multicheck-wrap .k-check-all + label")).ClickWithTimeout();
        }
        
        public void Search(string keys)
        {
            Driver.FindElement(By.CssSelector(ID + " .k-textbox input")).SendKeys(keys);
            Driver.WaitForAngular();
        }

        public void SelectOption(string label)
        {
            IEnumerable<NgWebElement> options = null;

            try
            {
                options = FindFilterMenu().FindElements(By.CssSelector(".k-multicheck-wrap label"));
                var filter = options.First(x => x.Text.Contains(label));
                filter.WithJs().Click();
            }
            catch (Exception ex)
            {
                if (options == null)
                    throw new Exception("Cannot find option '" + label + "'", ex);

                throw new Exception("Cannot find option '" + label + "', available options: [" + string.Join(", ", options.Select(x => x.Text)) + "]", ex);
            }
        }
    }

    class AngularDateGridFilter : AngularGridFilter
    {
        public AngularDateGridFilter(NgWebDriver driver, string grid, int col) : base(driver, grid, col)
        {
        }

        public DatePicker DatePicker => new DatePicker(Driver, "date" + Col);

        public SelectElement Operator => new SelectElement(Driver.FindElement(By.Id("dateOperator" + Col)));

        public void SetDateIsOnOrAfter(DateTime date, bool clearBeforeEntry = false)
        {
            Operator.SelectByText("Is On or After");

            DatePicker.Enter(date, clearBeforeEntry);
        }

        public void SetDateIsBefore(DateTime date, bool clearBeforeEntry = false)
        {
            Operator.SelectByText("Is Before");

            DatePicker.Enter(date, clearBeforeEntry);
        }

        public void SetDateIsEqual(DateTime date, bool clearBeforeEntry = false)
        {
            Operator.SelectByText("Is Equal");

            DatePicker.Enter(date, clearBeforeEntry);
        }
    }

    class AngularTextGridFilter : AngularGridFilter
    {
        public AngularTextGridFilter(NgWebDriver driver, string grid, int col) : base(driver, grid, col)
        {
        }

        public TextInput TextInput => new TextInput(Driver).ById("text" + Col);

        public SelectElement Operator => new SelectElement(Driver.FindElement(By.Id("textOperator" + Col)));

        public void SelectStartsWith(string text)
        {
            Operator.SelectByText("Starts With");

            TextInput.Input(text);
        }

        public void SelectTextEquals(string text)
        {
            Operator.SelectByText("Is Equal");

            TextInput.Input(text);
        }

        public void SelectTextContains(string text)
        {
            Operator.SelectByText("Contains");

            TextInput.Input(text);
        }
    }
}