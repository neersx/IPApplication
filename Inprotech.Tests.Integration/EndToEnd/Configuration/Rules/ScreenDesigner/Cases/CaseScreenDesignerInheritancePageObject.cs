using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.ScreenDesigner.Cases
{
    internal class CaseScreenDesignerInheritancePageObject : DetailPage
    {
        public CaseScreenDesignerInheritancePageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement InheritanceTree => Driver.FindElement(By.Id("inheritanceTree"));
        public NgWebElement[] InheritanceTreeItems => Driver.FindElements(By.CssSelector("#inheritanceTree .k-in")).ToArray();

        public NgWebElement ToggleSummary => Driver.FindElement(By.CssSelector("action-buttons div.switch label"));
        public string CriteriaHeader => Driver.FindElement(By.CssSelector("header #criteriaReference h5")).WithJs().GetInnerText();

        public NgWebElement[] CriteriaDetails => Driver.FindElements(By.CssSelector("ipx-inheritance-detail span.text")).ToArray();

    }
}