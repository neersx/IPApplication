using System.Linq;
using System.Web.UI.WebControls;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.PriorArt.Maintenance
{
    public class PriorArtMaintenanceHelper
    {
        public static void CheckMaintenanceTab(NgWebDriver driver, string description, string caseReference = null)
        {
            var maintenanceTab = driver.WindowHandles.Last();
            driver.SwitchTo().Window(maintenanceTab);
            driver.With<PriorArtMaintenancePageObjects>(page =>
            {
                Assert.True(page.DescriptionText.Contains(description), $"Expected Description to be displayed in the header but was {page.DescriptionText}");
                if (string.IsNullOrEmpty(caseReference))
                {
                    Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.CssSelector("div#caseAndSourceDetails > div.case-ref-div > span.text")), "Expected Case Reference to be hidden in header");
                }
                else
                {
                    Assert.True(page.CaseReferenceText.Contains(caseReference), $@"Expected Case Reference to be displayed in the header but was {page.CaseReferenceText}");
                }

            });
        }
    }
    public class PriorArtMaintenancePageObjects : PageObject
    {
        public PriorArtMaintenancePageObjects(NgWebDriver driver) : base(driver)
        {
        }
        public NgWebElement NotificationMessage => Driver.FindElement(By.ClassName("flash_alert"));
        public ButtonInput SaveButton => new ButtonInput(Driver).ByCssSelector("ipx-save-button button");
        public ButtonInput DeleteButton => new ButtonInput(Driver).ByCssSelector("ipx-delete-button");
        public NgWebElement MessageDiv => Driver.FindElement(By.ClassName("flash_alert"));
        NgWebElement MultiStep => Driver.FindElement(By.Id("priorart-multi-header"));
        public NgWebElement ChangeFirstLinked => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_change-first-linked']"));
        public NgWebElement UpdatePriorArtStatus => Driver.FindElement(By.TagName("ipx-bulk-actions-menu")).FindElement(By.ClassName("cpa-icon-edit"));
        public NgWebElement RemoveLinkedCases => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_remove-linked-case']"));
        public UpdateIsFirstLinkedModal IsFirstLinkedModal => new UpdateIsFirstLinkedModal(Driver);
        public UpdatePriorArtStatusModal UpdatePriorArtStatusModal => new UpdatePriorArtStatusModal(Driver);
        public void GoToStep(int step)
        {
            MultiStep.FindElement(By.Id($"step_{step - 1}")).WithJs().Click();
        }

        public AngularKendoGrid CitationsList => new AngularKendoGrid(Driver, "associatedArtList");
        public AngularKendoGrid LinkedCasesList => new AngularKendoGrid(Driver, "linkedCasesList");
        public ButtonInput LinkCasesButton => new ButtonInput(Driver).ById("btnLinkCases");
        public ButtonInput LinkFamilyListOrNameButton => new ButtonInput(Driver).ById("btnLinkFamilyListOrName");
        public string CaseReferenceText => Driver.FindElement(By.CssSelector("div#caseAndSourceDetails > div.case-ref-div > span.text")).Text;
        public string DescriptionText => Driver.FindElement(By.CssSelector("div#caseAndSourceDetails > div.source-ref-div > span.text")).Text;
    }

    public class CreateSourcePageObjects : PageObject
    {
        public CreateSourcePageObjects(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }
        public ButtonInput IpoIssuedButton => new ButtonInput(Driver).ById("ipo");
        public ButtonInput LiteratureButton => new ButtonInput(Driver).ById("patentLiterature");
        public AngularDropdown Source => new AngularDropdown(Driver).ByName("sourceType");
        public IpxTextField OfficialNumber => new IpxTextField(Driver).ByName("officialNumber");
        public IpxTextField KindCode => new IpxTextField(Driver).ByName("kindCode");
        public IpxTextField Title => new IpxTextField(Driver).ByName("title");
        public IpxTextField InventorName => new IpxTextField(Driver).ByName("inventorName");
        public IpxTextField ReferenceParts => new IpxTextField(Driver).ByName("referenceParts");
        public IpxTextField Comments => new IpxTextField(Driver).ByName("comments");
        public IpxTextField Citation=> new IpxTextField(Driver).ByName("citation");
        public IpxTextField Abstract=> new IpxTextField(Driver).ByName("abstract");
        public IpxTextField Publisher => new IpxTextField(Driver).ByName("publisher");
        public NgWebElement Publication => Driver.FindElement(By.CssSelector("ipx-text-field[name='publication'] textarea"));
        public IpxTextField Description => new IpxTextField(Driver).ByName("description");
    }
    
    public class UpdateIsFirstLinkedModal : ModalBase
    {

        public NgWebElement ApplyButton => Modal.FindElement(By.TagName("ipx-save-button"));
        public AngularCheckbox KeepCurrent => new AngularCheckbox(Driver);
        public UpdateIsFirstLinkedModal(NgWebDriver driver, string id = "updatFirstLinked") : base(driver, id)
        {
        }
    }

    public class UpdatePriorArtStatusModal : ModalBase
    {

        public NgWebElement SaveButton => Modal.FindElement(By.Id("save"));
        public AngularPicklist Status => new AngularPicklist(Driver).ByName("priorArtStatus");
        public UpdatePriorArtStatusModal(NgWebDriver driver, string id = "updatePriorArtStatus") : base(driver, id)
        {
        }
    }

    public class AssociatePriorArtPageObjects : PageObject
    {
        public AssociatePriorArtPageObjects(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public ButtonInput SearchButton => new ButtonInput(Driver).ById("btnPriorArtSearch");
    }

    public class LinkCasesDialog : MaintenanceModal
    {
        readonly NgWebDriver _driver;

        public LinkCasesDialog(NgWebDriver driver, string name) : base(driver, name)
        {
            _driver = driver;
        }

        public AngularCheckbox AddAnother => new AngularCheckbox(_driver, Modal).ByName("addAnother");
        public NgWebElement SaveButton => Modal.FindElement(By.CssSelector("ipx-save-button")).FindElement(By.TagName("button"));
        public void CloseModal()
        {
            Modal.FindElement(By.CssSelector("ipx-close-button button")).ClickWithTimeout();
        }

        public AngularPicklist CaseReference => new AngularPicklist(_driver).ByName("caseReference");
        public AngularPicklist CaseFamily => new AngularPicklist(_driver).ByName("caseFamily");
        public AngularPicklist CaseLists => new AngularPicklist(_driver).ByName("caseLists");
        public AngularPicklist CaseName => new AngularPicklist(_driver).ByName("caseName");
        public AngularPicklist NameType => new AngularPicklist(_driver).ByName("nameType");
    }

    public class FamilyCaselistNamePageObjects : PageObject
    {
        public FamilyCaselistNamePageObjects(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public ButtonInput RefreshButton => new ButtonInput(Driver).ByName("refresh");
        public AngularKendoGrid FamilyCaselistGrid => new AngularKendoGrid(Driver, "familyCaselist");
        public AngularKendoGrid FamilyCaseDetailGrid => new AngularKendoGrid(Driver, "caseDetailsGrid");
        public AngularKendoGrid LinkedNameGrid => new AngularKendoGrid(Driver, "name");

    }
}
