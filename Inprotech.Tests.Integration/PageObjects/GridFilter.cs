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
    class GridFilter : PageObject
    {
        protected readonly string Col;
        protected readonly string Grid;
        protected readonly string ID;

        public GridFilter(NgWebDriver driver, string grid, string col) : base(driver)
        {
            ID = '#' + grid + "_filter_" + col;
            Col = col;
            Grid = grid;
        }

        public virtual NgWebElement FilterButton()
        {
            return Driver.FindElement(By.CssSelector("#" + Grid + " th[data-field=\"" + Col + "\"] .k-grid-filter"));
        }

        public void Open(bool waitForBlockUi = false)
        {
            if (waitForBlockUi) Driver.WaitForBlockUi();

            // filter opens, loads contents then resizes
            // resizing may leave some of the elements out of scroll view
            // before opening, scroll down a bit if filter is too close to the bottom of the page
            var filterButton = FilterButton();
            filterButton.WithJs().ScrollIntoView();

            // the grid itself may be scrollable
            // make sure that filter button is inside the view

            try
            {
                var gridScroll = Driver.FindElement(By.CssSelector("#" + Grid + " .k-grid-content"));

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
            OpenFilterWithRetry(filterButton);
        }

        void OpenFilterWithRetry(NgWebElement filterButton, int retryCount = 0)
        {
            filterButton.ClickWithTimeout();
            var filterPopup = Driver.FindElements(By.CssSelector(ID)).FirstOrDefault();
            if (retryCount < 3 && (filterPopup == null || !filterPopup.Displayed))
            {
                OpenFilterWithRetry(filterButton, retryCount + 1);
            }
        }

        public void Dismiss()
        {
            var filterButton = FilterButton();

            filterButton.WithJs().ScrollIntoView();

            filterButton.ClickWithTimeout();
        }

        public void Filter()
        {
            Driver.FindElement(By.CssSelector(ID + " button[type=submit]")).WithJs().Click();
            Driver.WaitForGridLoader();
            Driver.WaitForAngular();
        }

        public void Clear()
        {
            var selector = ID + " button[type=reset]";
            Driver.FindElement(By.CssSelector(selector)).WithJs().Click();
            Driver.WaitForGridLoader();
            Driver.WaitForAngularWithTimeout();
        }
    }

    class MultiSelectGridFilter : GridFilter
    {
        public MultiSelectGridFilter(NgWebDriver driver, string grid, string col) : base(driver, grid, col)
        {
        }

        public int ItemCount => Driver.FindElements(By.CssSelector(ID + " ul.k-multicheck-wrap li:not([style='display: none;']) input:not([name='all'])")).Count;

        public int CheckedItemCount => Driver.FindElements(By.CssSelector(ID + " .k-multicheck-wrap input:checked:not(.k-check-all)")).Count;

        public String[] SelectedValues => Driver.FindElements(By.CssSelector(ID + " .k-multicheck-wrap input:checked:not(.k-check-all)")).Select(e => e.Value()).ToArray();

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
                options = Driver.FindElements(By.CssSelector(ID + " .k-multicheck-wrap label"));
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

    class DateGridFilter : GridFilter
    {
        public DateGridFilter(NgWebDriver driver, string grid, string col) : base(driver, grid, col)
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

    class TextGridFilter : GridFilter
    {
        public TextGridFilter(NgWebDriver driver, string grid, string col) : base(driver, grid, col)
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