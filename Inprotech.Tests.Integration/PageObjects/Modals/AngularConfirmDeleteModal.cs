using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Modals
{
    public class AngularConfirmDeleteModal : ModalBase
    {
        const string Id = "confirmDeleteModal";

        public AngularConfirmDeleteModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public NgWebElement Cancel => Modal.FindElement(By.CssSelector("button[name='Cancel']"));
        public NgWebElement Delete => Modal.FindElement(By.CssSelector("button[name='delete']"));
        public AngularCheckbox DeleteOptionCheckbox => new AngularCheckbox(Driver).ById("deleteOption");
    }
}