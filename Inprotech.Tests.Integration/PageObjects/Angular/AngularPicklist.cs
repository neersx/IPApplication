using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class AngularPicklist : PageObject
    {
        string _selector;

        public AngularPicklist(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        string Selector
        {
            get
            {
                if (_selector == null)
                {
                    throw new Exception("Selector is not initialised yet. Please specify selector with By* methods e.g. ById");
                }

                return _selector;
            }
            set => _selector = value;
        }
        string AutocompleteSelector
        {
            get
            {
                var id = Typeahead.GetAttribute("id");
                return "ipx-autocomplete[id='" + id + "']";
            }
        }

        public bool Enabled => !Typeahead.WithJs().IsDisabled();

        public bool Displayed => Typeahead.WithJs().IsVisible();

        public bool ModalDisplayed => FindElement(By.CssSelector(".modal-dialog")).Displayed;

        public bool Exists => FindElements(By.CssSelector(Selector)).Any();

        public NgWebElement Typeahead => FindElement(By.CssSelector(Selector + " .typeahead-wrap input.typeahead"));

        public NgWebElement Element => FindElement(By.CssSelector(Selector));

        public ReadOnlyCollection<NgWebElement> TypeAheadList
        {
            get
            {
                new DriverWait(Driver).ForVisible(By.CssSelector(AutocompleteSelector));

                // list can appear outside of container so use _driver
                var lines = Driver.FindElements(By.CssSelector(AutocompleteSelector + " .suggestion-list .suggestion-item"));

                return lines;
            }
        }

        public string InputValue => Typeahead.WithJs().GetValue();

        public IEnumerable<string> Tags
        {
            get
            {
                var listSelector = By.CssSelector(Selector + " .typeahead-wrap .tags .label-tag");

                new WebDriverWait(Driver, TimeSpan.FromSeconds(5))
                    .Until(ExpectedConditions.ElementIsVisible(listSelector));

                return FindElements(listSelector).Select(_ => _.WithJs().GetInnerText().Trim());
            }
        }

        public void ClearTags()
        {
            var listSelector = By.CssSelector(Selector + " .typeahead-wrap .tags .label-tag a");
            FindElements(listSelector).ToList().ForEach(x=> x.ClickWithTimeout());
        }

        public IEnumerable<string> SelectedTag
        {
            get
            {
                var itemSelector = By.CssSelector(Selector + " .typeahead-wrap .tags .selected");

                new WebDriverWait(Driver, TimeSpan.FromSeconds(5))
                    .Until(ExpectedConditions.ElementIsVisible(itemSelector));

                return FindElements(itemSelector).Select(_ => _.WithJs().GetInnerText().Trim());
            }
        }
        public NgWebElement SearchButton => FindElement(By.CssSelector(Selector + " span .cpa-icon-ellipsis-h"));

        public NgWebElement Error => FindElement(By.CssSelector(Selector + " .cpa-icon-exclamation-triangle"));

        public bool HasError => Error.WithJs().IsVisible();

        public AngularKendoGrid SearchGrid => new AngularKendoGrid(Driver, "picklistResults");

        public NgWebElement TogglePreviewSwitch => Driver.FindElement(By.CssSelector("div.modal-header-controls div.switch label"));

        public NgWebElement InfoBubble => Driver.FindElements(By.CssSelector("span.inline-dialog span.cpa-icon-question-circle")).Last();

        public AngularPicklist ById(string id)
        {
            Selector = '#' + id;
            return this;
        }

        public AngularPicklist ByName(string name)
        {
            Selector = string.Format($"ipx-typeahead[name='{name}']");
            return this;
        }

        public AngularPicklist ByName(string containerSelector, string name)
        {
            Selector = $"{containerSelector} ipx-typeahead[name=\"{name}\"]";
            return this;
        }

        public AngularPicklist SendKeys(string value)
        {
            Typeahead.SendKeys(value);
            Driver.WaitForAngularWithTimeout();

            return this;
        }

        public AngularPicklist EnterExactSelectAndBlur(string value)
        {
            SendKeys(value);
            SendKeys(Keys.ArrowDown);
            SendKeys(Keys.ArrowDown);
            SendKeys(Keys.Tab);

            return this;
        }

        public string GetText()
        {
            return Typeahead.WithJs().GetValue();
        }

        public void EnterAndSelect(string value, int? index= null)
        {
            Typeahead.Clear();
            SendKeys(value);
            TypeAheadList[index ?? 0].ClickWithTimeout();
            Driver.WaitForAngularWithTimeout();
        }

        public void SelectByIndex(int index)
        {
            Typeahead.Clear();
            SendKeys(Keys.ArrowDown);
            TypeAheadList.First().ClickWithTimeout();
            Driver.WaitForAngularWithTimeout();
        }

        public void Clear()
        {
            Typeahead.Clear();
            ClearTags();
        }

        public bool TypeAheadContains(string expectedValue)
        {
            try
            {
                SendKeys(expectedValue.Substring(0, 1));

                return TypeAheadList
                    .Select(x => x.Text)
                    .Select(x =>
                            {
                                var pos = x.IndexOf(") ", StringComparison.InvariantCulture);
                                return pos >= 0 ? x.Substring(pos + 2) : x;
                            })
                    .Contains(expectedValue);
            }
            finally
            {
                Typeahead.Clear();
            }
        }

        public bool AngularPicklistContains(string expectedValue)
        {
            try
            {
                OpenPickList(expectedValue);
                var result = SearchGrid.CellTextByBinding(0, "dataItem.value");

                return result == expectedValue;
            }
            finally
            {
                Close();
            }
        }

        public void SelectItem(string value)
        {
            SendKeys(value);
            Blur();
        }

        public void Click()
        {
            Typeahead.ClickWithTimeout();
        }

        public AngularPicklist Blur()
        {
            // Tab key doesn't work in IE e2e
            FindElement(By.CssSelector(Selector + " .input-action")).ClickWithTimeout();
            Driver.WaitForAngularWithTimeout();

            return this;
        }

        public void OpenPickList(string searchText = null)
        {
            SearchButton.ClickWithTimeout();
            Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));

            SearchFor(searchText);
        }

        public void Apply()
        {
            FindElements(By.CssSelector(".modal-content .btn-save")).Last().ClickWithTimeout();
        }

        public void Close()
        {
            var button = Driver.FindElements(By.CssSelector(".modal-content .btn-discard")).Last();
            var actions = new Actions(Driver);
            // this is to avoid any tooltips obscuring the button from being clicked
            actions.MoveToElement(button).Perform();
            button.WithJs().Click();
        }

        public void AddAngularPicklistItem()
        {          
            Driver.FindElement(By.CssSelector(".cpa-icon-plus-circle")).ClickWithTimeout();
        }

        public void SearchFor(string searchText)
        {
            if (!string.IsNullOrEmpty(searchText))
            {
                var searchField = FindElement(By.CssSelector("ipx-picklist-search-field .input-wrap input[type=text]"));
                searchField.Clear();
                searchField.SendKeys(searchText);
                ModalSearchButton().ClickWithTimeout();
            }

            Driver.WaitForAngular();
        }

        public NgWebElement ModalSearchButton()
        {
            return FindElement(By.CssSelector("ipx-icon-button[buttonicon=search]"));
        }

        public void SelectFirstGridRow()
        {
            SelectRow(0);
        }

        public void SelectRow(int index)
        {
            SearchGrid.Rows[index].WithJs().Click();
        }

        public static string GetInputValue(NgWebElement container, string selector)
        {
            return container.FindElement(By.CssSelector("ipx-typeahead" + selector + " input")).GetAttribute("value");
        }

        public void EditRow(int row)
        {
            ClickRowButton(row, "span.cpa-icon.cpa-icon-pencil-square-o");
        }

        public void DeleteRow(int row)
        {
            ClickRowButton(row, "span.cpa-icon.cpa-icon-trash");
        }

        public void DuplicateRow(int row)
        {
            ClickRowButton(row, "span.cpa-icon.cpa-icon-files-o");
        }

        public void ViewRow(int row)
        {
            ClickRowButton(row, "span.cpa-icon.cpa-icon-info-circle");
        }

        public void ClickRowButton(int row, string button)
        {
            SearchGrid.Rows[row].FindElement(By.CssSelector(button)).Click();
            Driver.HoverOff();
        }

        public bool IsRowButtonAvailable(int row, string button)
        {
            return SearchGrid.Rows.First().FindElements(By.Name(button)).Any();
        }

        public void NavigateToNext()
        {
            FindElement(By.CssSelector(".modal-nav button[ng-click=\"vm.navigation.next()\"]")).WithJs().Click();
        }

        public void NavigateToFirst()
        {
            FindElement(By.CssSelector(".modal-nav button[ng-click=\"vm.navigation.first()\"]")).WithJs().Click();
        }

        public void NavigateToPrev()
        {
            FindElement(By.CssSelector(".modal-nav button[ng-click=\"vm.navigation.prev()\"]")).WithJs().Click();
        }

        public void NavigateToLast()
        {
            FindElement(By.CssSelector(".modal-nav button[ng-click=\"vm.navigation.last()\"]")).WithJs().Click();
        }

        public NgWebElement ColumnMenuButton()
        {
            return FindElement(By.CssSelector("ipx-picklist-modal-search div.grid-columns button"));
        }

        public NgWebElement ColumnMenuList()
        {
            return FindElement(By.CssSelector(".grid-columns-list"));
        }

        public void ToggleGridColumn(string column)
        {
            FindElement(By.CssSelector(".grid-columns-list")).FindElement(By.CssSelector("li[data-field=\"" + column + "\"] label")).WithJs().Click();
        }

        public bool IsColumnChecked(string column)
        {
            return FindElement(By.CssSelector(".grid-columns-list")).FindElements(By.CssSelector("li[data-field=\"" + column + "\"] input")).Any(_ => _.Selected);
        }

        public NgWebElement ShowPreviewPane()
        {
            return FindElement(By.ClassName("detail-view"));
        }

        public NgWebElement ContextInfoElement()
        {
            return Driver.FindElement(By.CssSelector(".modal-body div.inline-readonly-list"));
        }
    }
}