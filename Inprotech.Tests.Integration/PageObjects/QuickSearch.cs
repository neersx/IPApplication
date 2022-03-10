using System.Collections.Generic;
using System.Linq;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    class QuickSearchControl : PageObject
    {
        public QuickSearchControl(NgWebDriver driver) : base(driver, driver.FindElement(By.TagName("ipx-quick-search"))) {}

        public NgWebElement Input => Container.FindElement(By.TagName("input"));
        public QuickSearchPicklist Picklist  
        {
            get
            {
                try
                {
                    return new QuickSearchPicklist(Driver, Container.FindElement(By.ClassName("quick-search-autocomplete")));
                }
                catch
                {
                    return null;
                }
            }
        }
    }

    class QuickSearchPicklist : PageObject
    {
        public QuickSearchPicklist(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public List<QuickSearchListItem> Items => Container.FindElements(By.ClassName("quick-search-suggestion-item"))
                                                           .Where(x => x.Text != "No results found")
                                                           .Select(x => new QuickSearchListItem(Driver, x))
                                                           .ToList();
    }

    class QuickSearchListItem : PageObject
    {
        public QuickSearchListItem(NgWebDriver driver, NgWebElement container) : base(driver, container)
        {
        }

        public bool IsHighlighted => Container.GetAttribute("class").Contains("highlighted");
        public string Irn => Container.FindElements(By.TagName("td"))[0].Text;
    }
}
