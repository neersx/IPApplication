using Protractor;
using SeleniumBy = OpenQA.Selenium.By;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class Selectors<T> : PageObject where T : class
    {
        public Selectors(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        protected SeleniumBy Selector { get; private set; }

        public NgWebElement Element => FindElement(Selector); // FindElement considers the container

        T Instance => this as T;

        public T By(SeleniumBy by)
        {
            Selector = by;
            return Instance;
        }

        public T ById(string id)
        {
            Selector = SeleniumBy.Id(id);
            return Instance;
        }

        public T ByName(string name)
        {
            Selector = SeleniumBy.Name(name);
            return Instance;
        }

        public T ByClassName(string className)
        {
            Selector = SeleniumBy.ClassName(className);
            return Instance;
        }

        public T ByCssSelector(string selector)
        {
            Selector = SeleniumBy.CssSelector(selector);
            return Instance;
        }

        public T ByTagName(string selector)
        {
            Selector = SeleniumBy.TagName(selector);
            return Instance;
        }
    }
}