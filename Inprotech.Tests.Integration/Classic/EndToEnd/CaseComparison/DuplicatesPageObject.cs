using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison
{
    public class DuplicatesPageObject : InboxPageObject
    {
        public DuplicatesPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement NavigateBackToInbox => Driver.FindElement(By.ClassName("cpa-icon-arrow-circle-nw"));
    }
}
