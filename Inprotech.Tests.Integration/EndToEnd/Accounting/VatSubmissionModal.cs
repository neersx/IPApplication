using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting
{
    public class VatSubmissionModal : ModalBase
    {
        public VatSubmissionModal(NgWebDriver driver) : base(driver)
        {
        }
        
        public string Title => Modal.FindElement(By.CssSelector(".modal-title")).Text;
        public NgWebElement CancelButton => Modal.FindElements(By.CssSelector("div.modal-footer button.btn")).First();
        public NgWebElement SubmitButton => Modal.FindElements(By.CssSelector("div.modal-footer button.btn-primary")).Last();
        public NgWebElement Declaration => Modal.FindElements(By.CssSelector("ip-checkbox div.input-wrap label")).Last();
        public NgWebElement DeclarationCheckbox => Modal.FindElements(By.CssSelector("ip-checkbox div.input-wrap input")).Last();
        public KendoGrid ErrorsGrid => new KendoGrid(Driver, "vat-error-log");
        public NgWebElement ExportButton => Modal.FindElements(By.ClassName("cpa-icon-file-pdf-o")).First();
        public NgWebElement HeaderDescriptionSpan => Modal.FindElements(By.Id("multipleEntityNames")).First();
        public void Close()
        {
            Modal.FindElement(By.ClassName("btn-discard")).TryClick();
        }
        public void Submit()
        {
            Modal.FindElement(By.ClassName("btn-discard")).TryClick();
        }
    }
}