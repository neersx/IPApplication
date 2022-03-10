using Inprotech.Tests.Integration.Extensions;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Modals
{
    public class ConfirmModal : ModalBase
    {
        const string Id = "confirmModal";

        public ConfirmModal(NgWebDriver driver, string id = null) : base(driver, id ?? Id)
        {
        }

        public NgWebElement Yes()
        {
            return Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Yes')]"));
        }

        public void Proceed()
        {
            Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Proceed')]")).ClickWithTimeout();
        }

        public NgWebElement PrimaryButton => Modal.FindElement(By.ClassName("btn-primary"));

        public NgWebElement No()
        {
            return Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'No')]"));
        }

        public NgWebElement Ok()
        {
            return Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Ok')]"));
        }

        public NgWebElement Save()
        {
            return Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Save')]"));
        }

        public NgWebElement Cancel()
        {
            return Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Cancel')]"));
        }

        public NgWebElement Replace()
        {
            return Modal.FindElement(By.XPath("//button[@type='button' and contains(text(),'Replace')]"));
        }
    }
}