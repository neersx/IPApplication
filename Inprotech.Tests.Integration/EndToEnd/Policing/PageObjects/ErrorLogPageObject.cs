using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects
{
    class ErrorLogPageObject : PageObject
    {
        public ErrorLogPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public Log ErrorLogGrid => new Log(Driver);

        public NgWebElement LevelUpButton => Driver.FindElement(By.CssSelector("span[class*='cpa-icon-arrow-circle-nw'"));

        public int InProgressIconCount => Driver.FindElements(By.CssSelector("span[class*='cpa-icon-exclamation-circle'")).Count;

        public class Log : KendoGrid
        {
            public Log(NgWebDriver driver) : base(driver, "errorlog")
            {
            }

            public void SetFocus()
            {
                Driver.FindElement(By.Id("inProgressErrorIcon")).Click();
            }

            public DateGridFilter ErrorDateFilter => new DateGridFilter(Driver, "errorlog", "errorDate");

            public TextGridFilter CaseReferenceFilter => new TextGridFilter(Driver, "errorlog", "caseRef");

            public TextGridFilter MessageFilter => new TextGridFilter(Driver, "errorlog", "message");

            public new QueueActionMenu ActionMenu => new QueueActionMenu(Driver);

            public TextGridFilter EventFilter => new TextGridFilter(Driver, "errorlog", "specificDescription-baseDescription");

            public TextGridFilter CriteriaFilter => new TextGridFilter(Driver, "errorlog", "eventCriteriaDescription");

            public class QueueActionMenu : ActionMenu
            {
                public QueueActionMenu(NgWebDriver driver) : base(driver, "policingErrorLog")
                {
                }

                public NgWebElement DeleteOption()
                {
                    return Option("delete");
                }
            }
        }
    }
}