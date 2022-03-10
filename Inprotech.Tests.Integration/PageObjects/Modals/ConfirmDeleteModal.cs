using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Modals
{
    public class ConfirmDeleteModal : ModalBase
    {
        const string Id = "confirmDeleteModal";

        public ConfirmDeleteModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public NgWebElement Cancel()
        {
            return Modal.FindElement(By.CssSelector("button[translate='Cancel']"));
        }

        public NgWebElement Delete()
        {
            return Modal.FindElement(By.CssSelector("button[translate='Delete']"));
        }
    }
}