using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess
{
    public class ScheduleDetailsPageObject : DetailPage
    {
        public ScheduleDetailsPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public RecentHistoryTopic RecentHistory => new RecentHistoryTopic(Driver);

        public class RecentHistoryTopic : Topic
        {
            const string TopicKey = "recent-history";
            const string GridId = "searchResults";

            public RecentHistoryTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            public KendoGrid Grid => new KendoGrid(Driver, GridId);

            public ErrorDetailsModal ErrorDetails => new ErrorDetailsModal(Driver);

            public string Status => Grid.CellText(0, "Status");

            public string Type => Grid.CellText(0, "Type");

            public string Started => Grid.CellText(0, "Started");

            public string Finished => Grid.CellText(0, "Finished");

            public string Cases => Grid.CellText(0, "Cases");

            public void OpenFailedExecutionDetails()
            {
                var failedStatusLink = Grid.Cell(0, 0).FindElements(By.TagName("a")).FirstOrDefault();

                failedStatusLink.WithJs().Click();
            }
        }
    }
    
    public class ErrorDetailsModal : ModalBase
    {
        const string Id = "ErrorDetails";

        public ErrorDetailsModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public InlineAlert InlineAlert => new InlineAlert(Driver);
    }
}