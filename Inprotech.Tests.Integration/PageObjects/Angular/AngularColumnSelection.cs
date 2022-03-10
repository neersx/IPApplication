using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
   public class AngularColumnSelection : PageObject
    {
        string _selector;
        string _popupSelector = "kendo-popup";

        public AngularColumnSelection(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
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

        public AngularColumnSelection ById(string id)
        {
            Selector = "ip-kendo-column-picker#" + id;
            return this;
        }

        public AngularColumnSelection ForGrid(string gridId)
        {
            Selector = $"#{gridId} ipx-grid-column-picker";
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
            //return FindElement(By.CssSelector($"{_popupSelector} .ipx-grid-columns-picker")).FindElements(By.CssSelector("li[data-field=\"" + column + "\"] input")).Any(_ => _.Selected);
            return FindElement(By.CssSelector($"{_popupSelector} .ipx-grid-columns-picker")).FindElements(By.CssSelector("li[data-field=\"" + column + "\"] input")).Any(_ => _.Selected);
        }

        public void ToggleGridColumn(string column)
        {
            FindElement(By.CssSelector($"{_popupSelector} .ipx-grid-columns-picker")).FindElement(By.CssSelector("li[data-field=\"" + column + "\"] label")).WithJs().Click();
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
            return FindElement(By.CssSelector($"{_popupSelector} .ipx-grid-columns-picker")).FindElements(By.CssSelector("li[data-field=\"" + column + "\"] input")).Any();
        }
    }
}
