using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects
{
    class DashboardPageObject : PageObject
    {
        public DashboardPageObject(NgWebDriver driver) : base(driver)
        {
            Summary = new SummaryPanelPageObject(driver);
            PolicingStatus = new PolicingStatusPanel(driver);
        }

        public SummaryPanelPageObject Summary { get; private set; }

        public PolicingStatusPanel PolicingStatus { get; private set; }

        public KendoGrid RequestGrid => new KendoGrid(Driver, "requestlog");

        public SelectElement ChartSelection()
        {
            return new SelectElement(Driver.FindElement(By.Id("chartSelection")));
        }

        public NgWebElement CurrentStatusChart()
        {
            return Driver.IsElementPresent(By.Id("currentStatusChart")) ? Driver.FindElement(By.Id("currentStatusChart")) : null;
        }

        public NgWebElement CurrentErrorStatusChart()
        {
            return Driver.IsElementPresent(By.Id("currentErrorStatusChart")) ? Driver.FindElement(By.Id("currentErrorStatusChart")) : null;
        }

        public NgWebElement RateChart()
        {
            return Driver.IsElementPresent(By.Id("rateChart")) ? Driver.FindElement(By.Id("rateChart")) : null;
        }

        public NgWebElement Warning()
        {
            return Driver.FindElement(By.CssSelector(".alert-warning"));
        }

        public NgWebElement ViewAllLogsLink()
        {
            return Driver.FindElements(By.Id("viewAllLogs")).FirstOrDefault();
        }

        public NgWebElement MaintainSavedRequestLink()
        {
            return Driver.FindElements(By.Id("viewRequests")).FirstOrDefault();
        }

        public NgWebElement ViewErrorLog()
        {
            return Driver.FindElements(By.Id("viewAllErrors")).FirstOrDefault();
        }
        
        public NgWebElement ExchangeIntegrationLink()
        {
            return Driver.FindElements(By.Id("viewExchangeIntegration")).FirstOrDefault();
        }

        public NgWebElement ViewExchangeIntegration => Driver.FindElement(By.Id("viewExchangeIntegration"));

        public class PolicingStatusPanel : PageObject
        {
            public PolicingStatusPanel(NgWebDriver driver) : base(driver)
            {
            }

            public bool IsRunning => WaitForAnyServerMessage().WithJs().GetInnerText().Contains("Running");

            public bool IsStopped => WaitForAnyServerMessage().WithJs().GetInnerText().Contains("Stopped");

            public bool IsCheckingStatus => WaitForAnyServerMessage().WithJs().GetInnerText().Contains("Checking");

            public NgWebElement Message()
            {
                return Driver.FindElement(By.CssSelector(".radio-status"));
            }

            public NgWebElement WaitForRunningMessage()
            {
                return Driver.Wait().ForVisible(By.CssSelector(".radio-status.saved"));
            }

            public NgWebElement WaitForStoppedMessage()
            {
                return Driver.Wait().ForVisible(By.CssSelector(".radio-status.error"));
            }

            public NgWebElement WaitForAnyServerMessage()
            {
                return Driver.Wait().ForVisible(By.CssSelector(".radio-status.saved,.radio-status.error"));
            }

            public NgWebElement ChangeStatusButton()
            {
                return Driver.FindElements(By.CssSelector(".btn.btn-icon i.cpa-icon-power")).FirstOrDefault();
            }
        }
    }

}