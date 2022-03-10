using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects
{
    class QueuePageObject : PageObject
    {
        public QueuePageObject(NgWebDriver driver) : base(driver)
        {
            Summary = new SummaryPanelPageObject(driver);
        }

        public SummaryPanelPageObject Summary { get; private set; }

        public RefreshSwitch AutomaticRefreshSwitch => new RefreshSwitch(Driver);

        public Queue QueueGrid => new Queue(Driver);

        public KendoGrid ErrorGrid => new KendoGrid(Driver, "error");

        public KendoGrid ErrorDetailGrid => new KendoGrid(Driver, "errordetail");

        public QueueActionMenu ActionMenu => new QueueActionMenu(Driver);

        public NextRunTime NextRunTimeModal => new NextRunTime(Driver);

        public NgWebElement BackToDashboardLink()
        {
            return Driver.FindElements(By.CssSelector("span[class*='cpa-icon-arrow-circle-nw'")).Last();
        }

        public NgWebElement ViewAllErrorsLink()
        {
            return Driver.FindElements(By.Id("viewAllErrors")).FirstOrDefault();
        }

        public class RefreshSwitch : PageObject
        {
            public RefreshSwitch(NgWebDriver driver) : base(driver)
            {
            }

            public NgWebElement Switch()
            {
                return Driver.FindElement(By.Id("refreshSwitch"));
            }

            public NgWebElement WrapperDiv()
            {
                return Driver.FindElement(By.ClassName("switch"));
            }

            public bool IsSelected()
            {
                //return Switch().GetAttribute("checked") == "true";
                return Switch().WithJs().HasClass("ng-not-empty");
            }

            public void Toggle()
            {
                // Extreme Flackiness for IE.
                Switch().WithJs().Click();
            }
        }

        public class QueueActionMenu : ActionMenu
        {
            public QueueActionMenu(NgWebDriver driver) : base(driver, "policingQueue")
            {
            }

            public NgWebElement HoldOption()
            {
                return Option( "Hold");
            }

            public NgWebElement ReleaseOption()
            {
                return Option("Release");
            }

            public NgWebElement DeleteOption()
            {
                return Option("Delete");
            }

            public NgWebElement HoldAllOption()
            {
                return Option("HoldAll");
            }

            public NgWebElement ReleaseAllOption()
            {
                return Option("ReleaseAll");
            }

            public NgWebElement DeleteAllOption()
            {
                return Option("DeleteAll");
            }

            public NgWebElement EditNextRun()
            {
                return Option("EditNextRunTime");
            }
        }

        public class Queue : KendoGrid
        {
            public Queue(NgWebDriver driver) : base(driver, "queue")
            {
            }

            public MultiSelectGridFilter CaseReferenceFilter => new MultiSelectGridFilter(Driver, "queue", "caseReference");

            public MultiSelectGridFilter UserFilter => new MultiSelectGridFilter(Driver, "queue", "user");

            public MultiSelectGridFilter StatusFilter => new MultiSelectGridFilter(Driver, "queue", "status");

            public MultiSelectGridFilter RequestTypeFilter => new MultiSelectGridFilter(Driver, "queue", "typeOfRequest");

            public int GetStatusCount(string status, string queueType = "all")
            {
                var columnIndex = queueType == "all" ? 2 : 1;

                var r = 0;
                for (var i = 0; i < MasterRows.Count; i++)
                {
                    var text = MasterCellText(i, columnIndex);
                    if (text == status)
                    {
                        r++;
                    }
                }
                return r;
            }

            public void SelectFirstItem()
            {
                Driver.WithJs().ScrollToTop();
                SelectRow(0);
            }
        }

        public class NextRunTime : PageObject
        {
            public NextRunTime(NgWebDriver driver) : base(driver)
            {
            }

            NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));

            public void Save()
            {
                Modal.FindElement(By.CssSelector(".btn-save")).WithJs().Click();
            }

            public NgWebElement Discard()
            {
                return Modal.FindElement(By.CssSelector(".btn-discard"));
            }

            public DatePicker DatePicker()
            {
                return new DatePicker(Driver, "date");
            }

            public NgWebElement Hour()
            {
                return Modal.FindElement(By.Id("hour"));
            }

            public NgWebElement Minute()
            {
                return Modal.FindElement(By.Id("minute"));
            }
        }
    }
}