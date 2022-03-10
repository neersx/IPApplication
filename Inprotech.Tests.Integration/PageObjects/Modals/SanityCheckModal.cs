using Inprotech.Tests.Integration.Extensions;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Modals
{
    public class SanityCheckModal : ModalBase
    {
        const string Id = "sanityCheckModal";

        public SanityCheckModal(NgWebDriver driver, string id = null) : base(driver, id ?? Id)
        {
        }

        public void Close()
        {
            Modal.FindElement(By.CssSelector("button[name='close']")).ClickWithTimeout();
        }

        public void IgnoreErrors()
        {
            Modal.FindElement(By.CssSelector("button[name='ignoreErrors']")).ClickWithTimeout();
        }
    }
}