using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search
{
    public class CasePreviewPageObject : PageObject
    {
        public CasePreviewPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public string Header => Driver.FindElement(By.CssSelector("#casePreviewPane header a")).WithJs().GetInnerText();

        public IEnumerable<string> Texts => Driver.FindElements(By.CssSelector("#casePreviewPane div span.text"))
                          .Where(_ => !string.IsNullOrWhiteSpace(_.Text))
                          .Select(_ => _.WithJs().GetInnerText()).ToArray();

        public IEnumerable<string> Names => Driver.FindElements(By.CssSelector("#caseSummaryNames span"))
                          .Select(_ => _.WithJs().GetInnerText());

        public NgWebElement DatesContainer => Driver.FindElement(By.CssSelector("#caseSummaryDates"));
    }
}
