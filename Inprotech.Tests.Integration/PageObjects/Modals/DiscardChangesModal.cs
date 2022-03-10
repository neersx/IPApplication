using Inprotech.Tests.Integration.Extensions;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Modals
{
    public class DiscardChangesModal : ModalBase
    {
        const string Id = "discardChangesModal";

        public DiscardChangesModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public void Discard()
        {
            Modal.FindElement(By.ClassName("btn-discard")).ClickWithTimeout();
        }

        public void Cancel()
        {
            Modal.FindElement(By.CssSelector("button[translate='.cancel']")).ClickWithTimeout();
        }
        public void CancelDiscard()
        {
            Modal.FindElement(By.CssSelector("button[name='cancel']")).ClickWithTimeout();
        }
    }
}