using Inprotech.Tests.Integration.Extensions;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Modals
{
    public class InfoModal : ModalBase
    {
        const string Id = "confirmModal";

        public InfoModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public void Ok()
        {
            Modal.FindElement(By.CssSelector("button[translate='button.ok']")).ClickWithTimeout();
        }

        public void Confirm()
        {
            Modal.FindElement(By.CssSelector("button[data-ng-click='confirm()']")).ClickWithTimeout();
        }
    }
}