using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Checklist.Search.Questions
{
    public class QuestionPicklistObject : PageObject
    {
        public QuestionPicklistObject(NgWebDriver driver) : base(driver)
        {
        }

        public AngularKendoGrid ResultGrid => new AngularKendoGrid(Driver, "picklistResults");
        public IpxTextField CodeField => new IpxTextField(Driver).ById("code");
        public IpxTextField QuestionField => new IpxTextField(Driver).ById("question");
        public IpxTextField InstructionsField => new IpxTextField(Driver).ById("instructions");
        public NgWebElement QuestionId => Driver.FindElement(By.CssSelector("#questionId > span"));
        public NgWebElement SaveButton => Driver.FindElement(By.CssSelector("ipx-save-button")).FindElement(By.TagName("button"));
        public NgWebElement CloseButton => Driver.FindElements(By.Name("times")).Last();
        public NgWebElement SearchField => Driver.FindElement(By.CssSelector("ipx-picklist-search-field .input-wrap input[type=text]"));
        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector("ipx-icon-button[buttonicon=search]"));
        public NgWebElement AddQuestionButton => Driver.FindElement(By.CssSelector("button.btn.plus-circle span.cpa-icon-plus-circle"));
    }
}