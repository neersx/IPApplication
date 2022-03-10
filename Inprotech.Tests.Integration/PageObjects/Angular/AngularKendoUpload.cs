using System.Linq;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Angular
{
    public class AngularKendoUpload : PageObject
    {
        readonly string _kendoUploadTag = "upload-wrapper";
        By _by;

        public AngularKendoUpload(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public NgWebElement Element => FindElement(_by);

        public NgWebElement FileInput => Element.FindElement(By.Name("files"));
        public NgWebElement SelectButton => Element.FindElement(By.CssSelector("div[role='button']"));
        public NgWebElement UploadButton => Element.FindElement(By.CssSelector("button[name='upload']"));
        public bool IsUploadButtonVisible => Element.FindElements(By.CssSelector("button[name='upload']")).Any();
        public bool IsClearButtonVisible => Element.FindElements(By.CssSelector("button[name='clear']")).Any();
        public NgWebElement ClearlButton => Element.FindElement(By.CssSelector("button[name='clear']"));
        public NgWebElement Label => Element.FindElement(By.TagName("label"));
        public NgWebElement[] FilesListItems => Element.FindElements(By.CssSelector("li.k-file")).ToArray();

        public string ErrorMessage(NgWebElement fileListItem)
        {
            var errorSpan = fileListItem.FindElements(By.ClassName("k-text-error"));
            return errorSpan.Any() ? errorSpan.First().Text : string.Empty;
        }

        public AngularKendoUpload ByName(string name)
        {
            _by = By.CssSelector($"{_kendoUploadTag}[name='{name}']");
            return this;
        }

        public AngularKendoUpload ById(string id)
        {
            _by = By.CssSelector($"#{id}");
            return this;
        }

        public AngularKendoUpload ByTagName()
        {
            _by = By.CssSelector(_kendoUploadTag);
            return this;
        }

        public void Upload(string filePath)
        {
            FileInput.SendKeys(filePath);
        }
    }
}