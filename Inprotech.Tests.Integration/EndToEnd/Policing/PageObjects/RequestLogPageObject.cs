using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects
{
    class RequestLogPageObject : PageObject
    {
        public RequestLogPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public Log RequestGrid => new Log(Driver);

        public NgWebElement ErrorIconCell => new Log(Driver).Cell(0, 0).FindElements(By.ClassName("error")).FirstOrDefault();

        public NgWebElement ViewAllErrorsLink => Driver.FindElements(By.Id("viewAllErrors")).FirstOrDefault();

        public KendoGrid ErrorGrid => new KendoGrid(Driver, "requestlogerror");

        public FormModal ErrorModal => new FormModal(Driver, "policingRequestLogerrordetail");

        public NgWebElement LevelUpButton => Driver.FindElement(By.CssSelector("span[class*='cpa-icon-arrow-circle-nw'"));

        public class Log : KendoGrid
        {
            public Log(NgWebDriver driver) : base(driver, "requestlog")
            {
            }

            public MultiSelectGridFilter PolicingNameFilter => new MultiSelectGridFilter(Driver, "requestlog", "policingName");

            public MultiSelectGridFilter StatusFilter => new MultiSelectGridFilter(Driver, "requestlog", "status");

            public DateGridFilter DateStartedFilter => new DateGridFilter(Driver, "requestlog", "startDateTime");

            public DateGridFilter DateCompletedFilter => new DateGridFilter(Driver, "requestlog", "finishDateTime");
        }
    }
}