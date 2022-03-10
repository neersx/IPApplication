using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects
{
    public class AttachmentListObj : ModalBase
    {
        public ContextMenuAttachment ContextMenu;
        public AttachmentListObj(NgWebDriver driver, NgWebElement container = null) : base(driver)
        {
            ContextMenu = new ContextMenuAttachment(driver);
        }

        public void OpenContextMenuForRow(int index)
        {
            AttachmentsGrid.Rows[index].FindElement(By.TagName("ipx-icon-button")).Click();
        }

        public void Open()
        {
            Driver.FindElement(By.Id("contextAttachments")).ClickWithTimeout();
        }

        public void Close()
        {
            Modal.FindElement(By.ClassName("btn-discard")).TryClick();
        }

        public void Add()
        {
            Modal.FindElement(By.ClassName("cpa-icon-plus-circle")).TryClick();
        }

        public AngularKendoGrid AttachmentsGrid => new AngularKendoGrid(Driver, "caseViewAttachments");

        public bool IsPriorArt(int row) => AttachmentsGrid.Cell(row, 1).FindElements(By.ClassName("cpa-icon-prior-art")).Count == 1;

        public string AttachmentName(int row) => AttachmentsGrid.CellText(row, "Attachment Name");

        public string Cycle(int row) => AttachmentsGrid.CellText(row, "Cycle");

        public string PageCount(int row) => AttachmentsGrid.CellText(row, "Page Count");
    }
}
