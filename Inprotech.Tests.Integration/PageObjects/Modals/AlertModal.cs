using Inprotech.Tests.Integration.Extensions;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Modals
{
    public class AlertModal : ModalBase
    {
        const string Id = "alertModal";

        public string Title => Modal.FindElement(By.Id("modalErrorLabel")).Text;
        public string Description => Modal.FindElement(By.CssSelector(".modal-body p")).Text;

        public AlertModal(NgWebDriver driver, string id = null) : base(driver, id ?? Id)
        {
        }

        public void Ok()
        {
            Modal.FindElement(By.CssSelector("button[name='cancel']")).ClickWithTimeout();
        }
    }
}