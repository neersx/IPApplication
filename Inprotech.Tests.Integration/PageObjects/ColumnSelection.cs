using System;
using System.Linq;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class ColumnSelection : PageObject
    {
        string _selector;

        public ColumnSelection(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
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
            set { _selector = value; }
        }

        public ColumnSelection ById(string id)
        {
            Selector = "ip-kendo-column-picker#" + id;
            return this;
        }

        public NgWebElement ColumnMenuButton => FindElement(By.CssSelector($"{Selector} div.grid-columns button"));

        public void ColumnMenuButtonClick()
        {
            ColumnMenuButton.WithJs().Click();
            Driver.WaitForAngular();
        }

        public bool IsColumnChecked(string column)
        {
            return FindElement(By.CssSelector($"{Selector} .grid-columns-list")).FindElements(By.CssSelector("li[data-field=\"" + column + "\"] input")).Any(_ => _.Selected);
        }

        public void ToggleGridColumn(string column)
        {
            FindElement(By.CssSelector($"{Selector} .grid-columns-list")).FindElement(By.CssSelector("li[data-field=\"" + column + "\"] label")).WithJs().Click();
            Driver.WaitForAngular();
        }

        public NgWebElement ResetButton => FindElement(By.CssSelector($"{Selector} div.grid-columns .footer a"));

        public void ResetColumns()
        {
            ResetButton.WithJs().Click();
            Driver.WaitForAngular();
        }

        public bool ContainsColumn(string column)
        {
            return FindElement(By.CssSelector($"{Selector} .grid-columns-list")).FindElements(By.CssSelector("li[data-field=\"" + column + "\"] input")).Any();
        }
    }
}