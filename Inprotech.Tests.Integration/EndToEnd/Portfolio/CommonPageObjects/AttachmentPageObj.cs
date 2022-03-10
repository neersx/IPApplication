using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects
{
    public class AttachmentPageObj : PageObject
    {
        public AttachmentPageObj(NgWebDriver driver) : base(driver)
        {
        }

        public AngularCheckbox AddAnother => new AngularCheckbox(Driver).ByName("addAnother");
        public string SelectedEntityLabelText => Driver.FindElement(By.CssSelector("div.title-header div.label-value")).Text;
        public IpxTextField AttachmentName => new IpxTextField(Driver).ByName("attachmentName");
        public AngularCheckbox IsPublic => new AngularCheckbox(Driver).ByName("allowClientAccess");
        public IpxTextField FilePath => new IpxTextField(Driver).ByName("filePath");
        public IpxTextField FileName => new IpxTextField(Driver).ByName("fileName");
        public AngularPicklist ActivityEvent => new AngularPicklist(Driver).ByName("event");
        public IpxTextField EventCycle => new IpxTextField(Driver).ByName("eventCycle");
        public AngularDropdown ActivityType => new AngularDropdown(Driver).ByName("activityType");
        public AngularDropdown ActivityCategory => new AngularDropdown(Driver).ByName("activityCategory");
        public DatePicker ActivityDate => new DatePicker(Driver, "activityDate");
        public AngularPicklist AttachmentType => new AngularPicklist(Driver).ByName("attachmentType");
        public AngularPicklist Language => new AngularPicklist(Driver).ByName("language");
        public IpxTextField PageCount => new IpxTextField(Driver).ByName("pageCount");
        public ButtonInput BrowseButton => new ButtonInput(Driver).ByName("browse");
        public ButtonInput BrowseDmsButton => new ButtonInput(Driver).ByName("browseDms");
        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
        public TreeView DirectoryTree => new TreeView(Driver);
        public KendoGrid FilesListGrid => new KendoGrid(Driver, "file-browser-documents");
        public string PathValue => Driver.FindElement(By.CssSelector("#selectedFolderPath")).Text;
        public string FileValue => Driver.FindElement(By.CssSelector("#selectedFile")).Text;
        public NgWebElement OkButton => Driver.FindElement(By.CssSelector(".modal-footer .btn-save"));
        public NgWebElement CancelButton => Driver.FindElement(By.CssSelector(".modal-footer .btn"));
        public AngularKendoUpload UploadComponent => new AngularKendoUpload(Driver).ById("fileUpload");

        public ButtonInput UploadFilesButton => new ButtonInput(Driver).ByName("upload");
        public ButtonInput RefreshButton => new ButtonInput(Driver).ByName("refresh");
        public NgWebElement UploadModal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog.modal-l"));

        public void Revert()
        {
            Driver.FindElement(By.ClassName("btn-revert")).TryClick();
        }

        public void Save()
        {
            Driver.FindElement(By.ClassName("btn-save")).TryClick();
        }

        public void SaveWithJs()
        {
            Driver.FindElement(By.ClassName("btn-save")).WithJs().Click();
        }

        public void Delete()
        {
            Driver.FindElement(By.ClassName("btn-discard")).TryClick();
        }     
        
        public void Close()
        {
            Driver.FindElement(By.CssSelector("span.cpa-icon-times")).WithJs().Click();
        }

        public void CloseModal(NgWebElement modal)
        {
            modal.FindElement(By.CssSelector("ipx-close-button button")).ClickWithTimeout();
        }
    }

    public class FileUploadExplorerObj : PageObject
    {
        public FileUploadExplorerObj(NgWebDriver driver) : base(driver)
        {
        }
    }
}