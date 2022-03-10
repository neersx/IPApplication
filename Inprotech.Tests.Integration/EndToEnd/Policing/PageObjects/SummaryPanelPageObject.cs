using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects
{
    internal class SummaryPanelPageObject : PageObject
    {
        public SummaryPanelPageObject(NgWebDriver driver) : base(driver)
        {
            Total = new Figures(driver, ".queue-items-total", "linkAll");

            Progressing = new Figures(driver, ".queue-items-progressing", "linkProgressing");

            RequiresAttention = new Figures(driver, ".queue-items-requires-attention", "linkRequiresAttention");

            OnHold = new Figures(driver, ".queue-items-on-hold", "linkOnHold");
        }

        public Figures Total { get; private set; }

        public Figures Progressing { get; private set; }

        public Figures RequiresAttention { get; private set; }

        public Figures OnHold { get; private set; }
    }
    
    internal class Figures : PageObject
    {
        readonly string _linkId;
        readonly string _textCssSelector;

        public Figures(NgWebDriver driver, string textCssSelector, string linkId) : base(driver)
        {
            _textCssSelector = textCssSelector;
            _linkId = linkId;
        }

        public int Value()
        {
            var strValue = Driver.WrappedDriver.ExecuteJavaScript<string>($"return $('{_textCssSelector}').text();");
            
            return string.IsNullOrEmpty(strValue) ? 0 : int.Parse(strValue);
        }

        public NgWebElement Link()
        {
            return Driver.FindElement(By.Id(_linkId));
        }
    }
}