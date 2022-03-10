using System.Linq;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail
{
    class CriteriaDetailPage : DetailPage
    {
        public CriteriaDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public CharacteristicsTopic CharacteristicsTopic => new CharacteristicsTopic(Driver);

        public EventsTopic EventsTopic => new EventsTopic(Driver);

        public EntriesTopic EntriesTopic => new EntriesTopic(Driver);

        public InheritanceModal InheritanceModal => new InheritanceModal(Driver);

        public InheritanceDeleteModal InheritanceDeleteModal => new InheritanceDeleteModal(Driver);

        public EventsForCaseModal EventsForCaseModal => new EventsForCaseModal(Driver);

        public new ButtonInput Save => new ButtonInput(Driver).ByClassName("btn-save");

        public new bool IsSaveDisplayed => Driver.FindElements(By.CssSelector("btn-save")).Any();

        public bool IsPermissionAlertDisplayed => Driver.FindElement(By.CssSelector("ip-inline-alert")).Displayed;

        public string PermissionAlertMessage => Driver.FindElement(By.CssSelector("ip-inline-alert")).Text;

        public string CriteriaNumber => Driver.FindElement(By.Id("criteriaNumber")).Text;

        public int CountOfCriteriaInheritedIcon() => Driver.FindElements(By.CssSelector("ip-sticky-header ip-inheritance-icon")).Count;

        public NgWebElement CriteriaInheritedIcon() => Driver.FindElement(By.CssSelector("ip-sticky-header [button-icon=\"inheritance\"]"));

        public NgWebElement CriteriaLabel => Driver.FindElement(By.XPath("//span[text()='Criteria']"));

        public NgWebElement CharacteristicsLabel => Driver.FindElement(By.XPath("//span[text()='Characteristics']"));

        public NgWebElement SearchButton => Driver.FindElement(By.XPath("//span[@name='search']"));

        public NgWebElement WorkflowDesignerButton => Driver.FindElement(By.CssSelector(".cpa-icon.no-color.cpa-icon-lg.cpa-icon-workflow-designer"));

        public NgWebElement PageInfo => Driver.FindElement(By.CssSelector(".k-pager-info.k-label"));

        public NgWebElement NextPageButton => Driver.FindElement(By.CssSelector(".k-pager-nav span.k-i-arrow-60-right"));
        
        public void ActivateActionsTab()
        {
            Driver.FindElements(By.CssSelector("div.topics > .topic-menu ul.nav-tabs a[data-toggle=tab] span[translate='sections.actions']")).Last().ClickWithTimeout();
        }

        public void ResetInheritance()
        {
            new PageAction(Driver, "resetInheritance").Click();
        }

        public void BreakInheritance()
        {
            new PageAction(Driver, "breakInheritance").Click();
        }

        public void LevelUp()
        {
            Driver.FindElements(By.CssSelector("span.cpa-icon-arrow-circle-nw")).Last().WithJs().Click();
        }

        public ResetEntryInheritanceConfirmation ResetEntryInheritanceConfirmation => new ResetEntryInheritanceConfirmation(Driver);
        public InheritanceBreakConfirmation BreakInheritanceConfirmation => new InheritanceBreakConfirmation(Driver);
    }

    public class InheritanceBreakConfirmation : ModalBase
    {
        const string Id = "inheritanceBreakConfirmation";
        public InheritanceBreakConfirmation(NgWebDriver driver) : base(driver, Id)
        {
        }

        public void Proceed()
        {
            Modal.FindElement(By.CssSelector("button[translate='button.proceed']")).ClickWithTimeout();
        }
    }

    class CharacteristicsTopic : Topic
    {
        const string TopicKey = "characteristics";

        public CharacteristicsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public TextInput CriteraName => new TextInput(Driver).ById("workflow-criteria-name");

        public bool IsCriteriaNameEnabled => Driver.FindElement(By.Id("workflow-criteria-name")).Enabled;

        public RadioButtonOrCheckbox ProtectCriteriaYes => new RadioButtonOrCheckbox(Driver, "protect-yes");

        public RadioButtonOrCheckbox ProtectCriteriaNo => new RadioButtonOrCheckbox(Driver, "protect-no");
        public RadioButtonOrCheckbox InUseYes => new RadioButtonOrCheckbox(Driver, "inUse-yes");

        public RadioButtonOrCheckbox InUseNo => new RadioButtonOrCheckbox(Driver, "inUse-no");

        public PickList JurisdictionPickList => new PickList(Driver).ByName("jurisdiction");
    }

    class EventsTopic : Topic
    {
        const string TopicKey = "events";
        const string GridId = "eventResults";
        public EventsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public KendoGrid EventsGrid => new KendoGrid(Driver, GridId);

        public PickList EventsPickList => new PickList(Driver).ByName("event");

        public void NavigateToEventControlByRowIndex(int rowIndex)
        {
            EventsGrid.MasterRows[rowIndex].FindElement(By.CssSelector("td a:first-child")).ClickWithTimeout();
        }

        public string[] GetAllEventIds()
        {
            return EventsGrid.MasterRows.Select(_ => _.FindElement(By.CssSelector("td a:first-child")).Text).ToArray();
        }

        public void SelectEventByIndex(int index)
        {
            EventsGrid.Cell(index, "Event Description").FindElement(By.TagName("a")).ClickWithTimeout();
        }

        public NgWebElement AddNewEventControlButton => Driver.FindElement(By.CssSelector("ip-kendo-grid[data-id='eventResults'] .cpa-icon-plus-circle"));

        public PickList FindEventPickList => new PickList(Driver).ByName("ip-workflows-maintenance-events", "event");

    }

    class EntriesTopic : Topic
    {
        const string TopicKey = "entries";
        const string GridId = "entriesResults";
        const string GridActionContext = "entries";

        public EntriesTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public KendoGrid Grid => new KendoGrid(Driver, GridId, GridActionContext);

        public EntryBasicDetails GetDataForRow(int rowIndex)
        {
            var isSeparator = Grid.Cell(rowIndex, 3).FindElements(By.ClassName("cpa-icon-check")).Count == 1;
            return new EntryBasicDetails(Grid.CellText(rowIndex, 2), isSeparator);
        }

        public void NavigateToDetailByRowIndex(int rowIndex)
        {
            Grid.MasterRows[rowIndex].FindElement(By.CssSelector("td a:first-child")).ClickWithTimeout();
        }

        public CreateEntryModal CreateEntryModal => new CreateEntryModal(Driver);
    }

    public class EntryBasicDetails
    {
        public EntryBasicDetails(string description, bool isSeparator)
        {
            Description = description;
            IsSeparator = isSeparator;
        }
        public string Description { get; set; }

        public bool IsSeparator { get; set; }
    }

    class InheritanceModal : ModalBase
    {
        const string Id = "inheritanceConfirmationModal";

        public InheritanceModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public void Proceed()
        {
            Modal.FindElement(By.CssSelector("button[translate='button.proceed']")).Click();
        }

        public void WithoutApplyToChildren()
        {
            Modal.FindElement(By.CssSelector("ip-checkbox[label='workflows.maintenance.applyToDescendants'] label")).Click();
        }
    }

    class InheritanceDeleteModal : ModalBase
    {
        const string Id = "inheritanceDeleteConfirmationModal";

        public InheritanceDeleteModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public void Delete()
        {
            Modal.FindElement(By.CssSelector("button[translate='Delete']")).ClickWithTimeout();
        }

        public void WithoutApplyToChildren()
        {
            Modal.FindElement(By.CssSelector("ip-checkbox[data-label='workflows.maintenance.applyToDescendants'] label")).ClickWithTimeout();
        }
    }

    class EventsForCaseModal : ModalBase
    {
        const string Id = "eventsForCaseModal";

        public EventsForCaseModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public void Proceed()
        {
            Modal.FindElement(By.CssSelector("button[translate='Proceed']")).ClickWithTimeout();
        }
    }

    class CreateEntryModal : ModalBase
    {
        const string Id = "createEntriesModal";

        public CreateEntryModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public TextInput EntryDescription => new TextInput(Driver).ByName("entryDescription");

        public void AsSeparator()
        {
            Modal.FindElement(By.CssSelector("ip-checkbox[ng-model='vm.isSeparator'] label")).ClickWithTimeout();
        }

        public void Save()
        {
            Modal.FindElement(By.Id("Save")).ClickWithTimeout();
        }
    }
}