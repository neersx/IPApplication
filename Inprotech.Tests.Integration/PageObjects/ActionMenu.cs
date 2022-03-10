using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class ActionMenu : PageObject
    {
        readonly NgWebElement _grid;
        readonly string _context;

        public ActionMenu(NgWebDriver driver, string context) : base(driver)
        {
            _context = context;
        }

        public ActionMenu(NgWebElement grid, string context) : base(grid.CurrentDriver())
        {
            _grid = grid;
            _context = context;
        }

        public void OpenOrClose()
        {
            Menu().WithJs().ScrollIntoView();
            Menu().WithJs().Click();
        }

        public void CloseMenu()
        {
            Menu().SendKeys(Keys.Tab);
        }

        public bool IsNotAvailable()
        {
            return Menu().IsNotAvailable();
        }

        public NgWebElement Menu()
        {
            if (_grid != null)
            {
                return _grid.FindElements(By.CssSelector(".dd-menu > .dd-link"))
                            .FirstOrDefault();
            }
            return Driver.FindElements(By.CssSelector(".dd-menu > .dd-link"))
                         .FirstOrDefault();
        }

        public IEnumerable<NgWebElement> Options(string function)
        {
            return Driver.FindElements(By.Id("bulkaction_" + _context + "_" + function));
        }

        public NgWebElement Option(string function)
        {
            return Options(function).FirstOrDefault();
        }

        public void SelectPage()
        {
            Driver.FindElement(By.Id($"{_context}_selectpage")).TryClick();
        }

        public void SelectAll()
        {
            Driver.FindElement(By.Name("selectall")).WithJs().Click();
        }

        public int SelectedItems()
        {
            var badge = _grid.FindElements(By.CssSelector("div.dd-menu button.dd-link span.badge"));
            return badge.Any() ? int.Parse(badge.First().WithJs().GetInnerText()) : 0;
        }

        public void ClearAll()
        {
            Driver.FindElement(By.CssSelector("div.dd-menu > div.dd-dropdown a .cpa-icon-times ~ span")).Click();
        }
    }

    public static class NgWebElementExtensionForActionMenu
    {
        public static bool Disabled(this NgWebElement element)
        {
            if (!element.GetAttribute("id").Contains("bulkaction_"))
            {
                throw new NotSupportedException("This is only meant to be used for Action Menu");
            }

            return element.WithJs().HasClass("disabled");
        }
    }
}