using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport
{
    public class ImportCasePageObject : PageObject
    {
        public ImportCasePageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement LevelUpButton => Driver.FindElements(By.CssSelector("div.page-title ip-level-up-button span")).Last();

        public IEnumerable<TemplateLink> StandardTemplates => Driver.FindElements(NgBy.Repeater("i in standardTemplates track by $index")).Select(element => new TemplateLink(Driver, element));

        public IEnumerable<TemplateLink> CustomTemplates => Driver.FindElements(NgBy.Repeater("i in customTemplates track by $index")).Select(element => new TemplateLink(Driver, element));

        bool ProgressbarIsHidden => Driver.WrappedDriver.ExecuteJavaScript<bool>("return $('.progress-striped:not(.active)').length == 1");

        public bool HasValidationError => Driver.WrappedDriver.ExecuteJavaScript<bool>("return $('.alert-danger:visible').length == 1");

        void WaitUntilProgressbarIsHidden()
        {
            // wait 5 minutes as import is a long process.
            // if this fails, the Retry and all subsequent import tests will fail as 
            // they still have to wait for the first one to complete before 
            // they can take acquire a lock for themselves.

            Driver.Wait().ForTrue(() => ProgressbarIsHidden, 300000);
        }

        public void Import(string filePath)
        {
            var fileInput = Driver.FindElement(By.CssSelector(".internal-file-input"));

            fileInput.SendKeys(filePath);

            WaitUntilProgressbarIsHidden();
        }
    }

    public class TemplateLink : PageObject
    {
        readonly NgWebElement _element;

        public TemplateLink(NgWebDriver driver, NgWebElement webElement) : base(driver)
        {
            _element = webElement;
        }

        public string Url => _element.FindElement(By.TagName("A")).GetAttribute("HREF");

        public string Text => _element.FindElement(By.TagName("A")).Text;

        public void Click()
        {
            _element.FindElement(By.TagName("A")).WithJs().Click();
        }
    }

    public static class EnumerableTemplateLink
    {
        public static void ClickByName(this IEnumerable<TemplateLink> source, string name)
        {
            source.Single(_ => _.Text == name).Click();
        }
    }
}