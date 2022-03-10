using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EntryControl
{
    internal class EntryControlPage : DetailPage
    {
        public EntryControlPage(NgWebDriver driver) : base(driver)
        {
            Header = new HeaderPageObject(driver);
            Definition = new DefinitionTopic(driver);
            Details = new DetailsTopic(driver);
            ChangeStatus = new ChangeStatusTopic(driver);
            Documents = new DocumentsTopic(driver);
            DisplayConditions = new DisplayConditionsTopic(driver);
            Steps = new StepsTopic(driver);
            EntryInheritanceConfirmationModal = new EntryInheritanceConfirmation(driver);
            ResetEntryInheritanceConfirmationModal = new ResetEntryInheritanceConfirmation(driver);
            CreateOrEditEntryEventModal = new CreateOrEditEntryEventModalDialog(driver);
            CreateOrEditStepModal = new CreateOrEditStepModalDialog(driver);
            UserAccess = new UserAccessTopic(driver);
        }

        public DetailsTopic Details { get; private set; }

        public HeaderPageObject Header { get; private set; }

        public DefinitionTopic Definition { get; private set; }

        public ChangeStatusTopic ChangeStatus { get; private set; }

        public DocumentsTopic Documents { get; private set; }

        public DisplayConditionsTopic DisplayConditions { get; private set; }

        public StepsTopic Steps { get; private set; }

        public UserAccessTopic UserAccess { get; private set; }

        public EntryInheritanceConfirmation EntryInheritanceConfirmationModal { get; set; }

        public ResetEntryInheritanceConfirmation ResetEntryInheritanceConfirmationModal { get; set; }

        public CreateOrEditEntryEventModalDialog CreateOrEditEntryEventModal { get; set; }

        public CreateOrEditStepModalDialog CreateOrEditStepModal { get; set; }

        public EntryInheritanceDeleteModal EntryInheritanceDeleteModal => new EntryInheritanceDeleteModal(Driver);

        public NgWebElement InheritanceIcon
        {
            get
            {
                var elements = Driver.FindElements(By.CssSelector("ip-sticky-header div.title-header ip-inheritance-icon"));
                if (elements == null || !elements.Any())
                    return null;
                return elements[0];
            }
        }

        public new NgWebElement LevelUpButton => Driver.FindElements(By.CssSelector("div.page-title ip-level-up-button span")).Last();

        public EntryControlActions Actions => new EntryControlActions(Driver);

        public void ActivateActionsTab()
        {
            Driver.FindElement(By.CssSelector("div.topics > .topic-menu ul.nav-tabs a[data-toggle=tab] span[translate='sections.actions']")).ClickWithTimeout();
        }

        public bool SectionTabVisible()
        {
            return Driver.FindElements(By.CssSelector("div.topics > .topic-menu ul.nav-tabs li.active a[data-toggle=tab] span[translate='sections.title']")).Any();
        }

        public class HeaderPageObject : PageObject
        {
            public HeaderPageObject(NgWebDriver driver) : base(driver)
            {
            }

            public string CriteriaNumber => Driver.FindElement(By.CssSelector("ip-sticky-header div.title-header .criteria-number")).Text;

            public string Description => Driver.FindElement(By.CssSelector("ip-sticky-header div.title-header .entry-desc")).Text;

            public bool SeparatorIndicator => Driver.FindElements(By.CssSelector("label[translate='workflows.entrycontrol.definition.isSeparator']")).Count == 1;
        }

        public class DefinitionTopic : Topic
        {
            const string TopicKey = "definition";

            public DefinitionTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            public string DescriptionText => Description.Input.GetAttribute("value");

            public string UserInstructionsText => UserInstruction.Input.GetAttribute("value");

            public IpTextField Description => new IpTextField(Driver).ByName("description");

            public IpTextField UserInstruction => new IpTextField(Driver).ByName("userInstruction");
        }

        public class DetailsTopic : Topic
        {
            const string TopicKey = "details";
            const string GridId = "detailsGrid";

            public DetailsTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            public int GridRowsCount => new KendoGrid(Driver, GridId).Rows.Count;

            public PickList OfficialNumberTypePl => new PickList(Driver).ByName("ip-workflows-entry-control-details", "officialNumberType");

            public PickList FileLocationPl => new PickList(Driver).ByName("ip-workflows-entry-control-details", "fileLocation");

            public string OfficialNumberTypeDescription => OfficialNumberTypePl.InputValue;

            public string FileLocationDescription => FileLocationPl.InputValue;

            public NgWebElement AtleastOneEventFlag => TopicContainer.FindElement(By.CssSelector("ip-checkbox[ng-model='vm.formData.atLeastOneEventFlag'] input"));

            public bool AtleastOneEventFlagValue => TopicContainer.FindElement(By.CssSelector("ip-checkbox[ng-model='vm.formData.atLeastOneEventFlag'] input")).Selected;

            public bool IsPoliceImmediatelyYesChecked => TopicContainer.FindElement(By.CssSelector("ip-radio-button[ng-model='vm.formData.policeImmediately'][ng-value='true'] input")).Selected;

            public bool IsPoliceImmediatelyNoChecked => TopicContainer.FindElement(By.CssSelector("ip-radio-button[ng-model='vm.formData.policeImmediately'][ng-value='false'] input")).Selected;
            public KendoGrid Grid => new KendoGrid(Driver, GridId);

            public void SelectEventRow(int rowId) => Grid.ClickRow(rowId);

            public bool AnyInherited => Grid.AnyInherited();

            public EventDetails GetEventDataForRow(int rowId)
            {
                return new EventDetails
                {
                    Inherited = new KendoGrid(Driver, GridId).Rows[rowId].FindElements(By.CssSelector(".cpa-icon-inheritance")).Count == 1,
                    EntryEvent = new KendoGrid(Driver, GridId).CellText(rowId, 2),
                    EventDateAttribute = new KendoGrid(Driver, GridId).CellText(rowId, 3),
                    DueDateAttribute = new KendoGrid(Driver, GridId).CellText(rowId, 4),
                    UpdateEvent = new KendoGrid(Driver, GridId).CellText(rowId, 5),
                    Period = new KendoGrid(Driver, GridId).CellText(rowId, 6),
                    Policing = new KendoGrid(Driver, GridId).CellText(rowId, 7),
                    DueDateResp = new KendoGrid(Driver,GridId).CellText(rowId,8),
                    OverrideEvent = new KendoGrid(Driver,GridId).CellText(rowId,9),
                    OverrideDue = new KendoGrid(Driver,GridId).CellText(rowId,10),
                };
            }

            public class EventDetails
            {
                public bool Inherited { get; set; }
                public string EntryEvent { get; set; }
                public string UpdateEvent { get; set; }
                public string EventDateAttribute { get; set; }
                public string DueDateAttribute { get; set; }

                public string Policing { get; set; }
                public string Period { get; set; }
                public string DueDateResp { get; set; }
                public string OverrideDue { get; set; }
                public string OverrideEvent { get; set; }
            }
        }

        public class ChangeStatusTopic : Topic
        {
            const string TopicKey = "changeStatus";

            public ChangeStatusTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            public PickList ChangeCaseStatusPl => new PickList(Driver).ByName("ip-workflows-entry-control-change-status", "caseStatus");

            public string ChangeCaseStatus => PickList.GetInputValue(TopicContainer, "[data-ng-model='vm.formData.changeCaseStatus']");

            public PickList ChangeRenewalStatusPl => new PickList(Driver).ByName("ip-workflows-entry-control-change-status", "renewalStatus");

            public string ChangeRenewalStatus => PickList.GetInputValue(TopicContainer, "[data-ng-model='vm.formData.changeRenewalStatus']");
        }

        public class DocumentsTopic : Topic
        {
            const string GridId = "documentsGrid";

            public DocumentsTopic(NgWebDriver driver) : base(driver, "documents")
            {
            }
            public KendoGrid Grid => new KendoGrid(Driver, GridId);
            public int GridRowsCount => Grid.Rows.Count;
            public bool AnyInherited => Grid.AnyInherited();

            public bool IsInheritedInFirstRow => Grid.Cell(0, 1).FindElements(By.CssSelector("ip-inheritance-icon")).Count > 0;

            public string DocumentName => DocumentPicklist(0).GetText();

            public bool IsProduceChecked => Grid.Cell(0, 3).FindElement(By.CssSelector("input")).Selected;

            public PickList DocumentPicklist(int rowId)
            {
                return new PickList(Driver).ByName("ip-kendo-grid[data-id='documentsGrid'] tbody>tr:nth-child(" + (rowId + 1) + ")", "document");
            }

            //public void ClickDelete(int row) => Grid.Rows[row].FindElement(By.CssSelector("ip-kendo-toggle-delete-button button")).TryClick();
            public void ClickMustProduce(int row) => Grid.Rows[row].FindElement(By.CssSelector("input[type=checkbox]")).WithJs().Click();
            public DocumentRow GetDataForRow(int rowId)
            {
                return new DocumentRow
                {
                    Inherited = Grid.Rows[rowId].FindElements(By.CssSelector(".cpa-icon-inheritance")).Count == 1,
                    DocumentName = DocumentPicklist(rowId).GetText(),
                    IsMandatory = Grid.Cell(rowId, 3).FindElement(By.CssSelector("ip-checkbox input")).Selected
                };
            }

            public class DocumentRow
            {
                public bool Inherited { get; set; }
                public string DocumentName { get; set; }
                public bool IsMandatory { get; set; }
            }
        }

        public class DisplayConditionsTopic : Topic
        {
            const string TopicKey = "displayConditions";

            public DisplayConditionsTopic(NgWebDriver driver) : base(driver, TopicKey)
            {
            }

            public string DisplayEventDescription => TopicContainer.FindElement(By.Name("displayEventNo")).FindElement(By.TagName("input")).GetAttribute("value");
            public string HideEventDescription => TopicContainer.FindElement(By.Name("hideEventNo")).FindElement(By.TagName("input")).GetAttribute("value");
            public string DimEventDescription => TopicContainer.FindElement(By.Name("dimEventNo")).FindElement(By.TagName("input")).GetAttribute("value");
            public PickList DisplayEventPl => new PickList(Driver).ByName("ip-workflows-entry-control-display-conditions", "displayEventNo");
            public PickList HideEventPl => new PickList(Driver).ByName("ip-workflows-entry-control-display-conditions", "hideEventNo");
            public PickList DimEventPl => new PickList(Driver).ByName("ip-workflows-entry-control-display-conditions", "dimEventNo");
        }

        public class StepsTopic : Topic
        {
            const string Key = "steps";

            public StepsTopic(NgWebDriver driver) : base(driver, Key)
            {
            }

            public KendoGrid Grid => new KendoGrid(Driver, Key);

            public int GridRowsCount => Grid.Rows.Count;

            public bool IsInheritedInFirstRow => Grid.Cell(0, 0).FindElements(By.CssSelector("ip-inheritance-icon")).Count > 0;
            public bool AnyInherited => Grid.AnyInherited();

            public string Title => Grid.CellText(0, 1);

            public string OriginalTitle => Grid.CellText(0, 2);

            public string Category => Grid.CellText(0, 3);

            public string CategoryValue => Grid.CellText(0, 4);

            public string ScreenTip => Grid.CellText(0, 5);

            public bool IsMandatory => Grid.CellIsSelected(0, 6);

            public void SelectRow(int rowId) => Grid.Rows[rowId].ClickWithTimeout();

            //public void ClickEdit(int row) => Grid.Rows[row].FindElement(By.CssSelector("[button-icon='pencil-square-o']")).ClickWithTimeout();

            //public void ClickDelete(int row) => Grid.Rows[row].FindElement(By.CssSelector("ip-kendo-toggle-delete-button button")).ClickWithTimeout();

            public Step GetDataForRow(int rowId)
            {
                return new Step
                {
                    Inherited = Grid.Rows[rowId].FindElements(By.CssSelector(".cpa-icon-inheritance")).Count == 1,
                    StepTitle = Grid.CellText(rowId, 2),
                    Title = Grid.CellText(rowId, 3),
                    UserTip = Grid.CellText(rowId, 4),
                    Mandatory = Grid.Cell(rowId,5).FindElement(By.CssSelector("ip-checkbox input")).Selected,
                    Categories = Grid.CellText(rowId, 6)
                };
            }

            public class Step
            {
                public bool Inherited { get; set; }
                public string StepTitle { get; set; }
                public string Title { get; set; }
                public string UserTip { get; set; }
                public bool Mandatory { get; set; }
                public string Categories { get; set; }
            }
        }

        public class UserAccessTopic : Topic
        {
            const string Key = "userAccess";

            PickList _rolesPickList;

            public UserAccessTopic(NgWebDriver driver) : base(driver, Key)
            {
            }

            public KendoGrid Grid => new KendoGrid(Driver, Key);

            public bool IsInheritedInFirstRow => Grid.Rows.First().FindElements(By.CssSelector("ip-inheritance-icon")).Count > 0;

            public string RoleName => Grid.CellText(0, 3);

            public PickList RolesPickList => _rolesPickList ?? (_rolesPickList = new PickList(Driver));
        }

        public class EntryInheritanceConfirmation : ModalBase
        {
            const string Id = "entryInheritanceConfirmation";

            public EntryInheritanceConfirmation(NgWebDriver driver) : base(driver, Id)
            {
            }

            public bool ApplyToDescendants => Modal.FindElement(By.CssSelector("ip-checkbox input")).Selected;

            public void Proceed(bool waitForAngular = true)
            {
                Modal.FindElement(By.CssSelector("button[translate='button.proceed']")).ClickWithTimeout(waitForAngular: waitForAngular);
            }

            public void Cancel()
            {
                Modal.FindElement(By.CssSelector("button[translate='button.cancel']")).ClickWithTimeout();
            }

            public void WithoutApplyToChildren()
            {
                if (ApplyToDescendants)
                    Modal.FindElement(By.CssSelector("ip-checkbox[data-label='workflows.entrycontrol.inheritanceConfirmation.checkboxLabel'] label")).ClickWithTimeout();
            }
            NgWebElement Div(string id) => Modal.FindElement(By.CssSelector($"div#{id}"));
            public bool IsCriteriaShownAsAffected(string criteriaId)
            {
                return Div("items").FindElement(By.LinkText(criteriaId)) != null;
            }

            public bool IsCriteriaShownAsBreaking(string criteriaId)
            {
                return Div("breakingItems").FindElement(By.LinkText(criteriaId)) != null;
            }

            public bool AffectedSectionIsDisplayed => Modal.FindElements(By.CssSelector($"div#items")).Count == 1;

            public bool BreakingSectionIsDisplayed => Modal.FindElements(By.CssSelector($"div#breakingItems")).Count == 1;
        }

        public class CreateOrEditEntryEventModalDialog : MaintenanceModal
        {
            public CreateOrEditEntryEventModalDialog(NgWebDriver driver) : base(driver)
            {
            }

            public PickList EntryEvent => new PickList(Driver).ByName(".modal", "entryEvent");
            public PickList UpdateEvent => new PickList(Driver).ByName(".modal", "eventToUpdate");
            public DropDown EventDate => new DropDown(Driver, Modal).ByName("eventDate");
            public DropDown DueDate => new DropDown(Driver, Modal).ByName("dueDate");
            public DropDown Period => new DropDown(Driver, Modal).ByName("period");
            public DropDown StopPolicing => new DropDown(Driver, Modal).ByName("stopPolicing");
            public DropDown DueDateResp => new DropDown(Driver, Modal).ByName("dueDateResp");
            public DropDown OverrideDueDate => new DropDown(Driver, Modal).ByName("overrideDueDate");
            public DropDown OverrideEventDate => new DropDown(Driver, Modal).ByName("overrideEventDate");
        }

        public class CreateOrEditStepModalDialog : MaintenanceModal
        {
            public CreateOrEditStepModalDialog(NgWebDriver driver) : base(driver)
            {
            }

            public PickList Screen => new PickList(Driver).ByName(".modal", "topic");
            public TextField Title => new TextField(Driver, "title");
            public TextField UserTip => new TextField(Driver, "userTip");
            public Checkbox IsMandatory => new Checkbox(Driver, Modal).ByModel("vm.formData.isMandatory");
            public PickList Category1 => new PickList(Driver).ByName(".modal", "categoryPicklist0");
            public PickList Category2 => new PickList(Driver).ByName(".modal", "categoryPicklist1");
        }

        internal class EntryControlActions : PageObject
        {
            public EntryControlActions(NgWebDriver driver) : base(driver)
            {
            }

            public void ResetInheritance()
            {
                new PageAction(Driver, "resetInheritance").Click();
            }

            public void BreakInheritance()
            {
                new PageAction(Driver, "breakInheritance").Click();
            }
        }

        internal class ResetEntryInheritanceConfirmation : ModalBase
        {
            const string Id = "inheritanceResetConfirmation";

            public ResetEntryInheritanceConfirmation(NgWebDriver driver) : base(driver, Id)
            {
            }

            public bool ApplyToDescendants => Modal.FindElement(By.CssSelector("ip-checkbox input")).Selected;

            public void Proceed()
            {
                Modal.FindElement(By.CssSelector("button[translate='button.proceed']")).ClickWithTimeout();
            }

            public void Cancel()
            {
                Modal.FindElement(By.CssSelector("button[translate='button.cancel']")).ClickWithTimeout();
            }

            public void WithoutApplyToChildren()
            {
                if (ApplyToDescendants)
                    Modal.FindElement(By.CssSelector("ip-checkbox[data-label='.checkboxLabel'] label")).ClickWithTimeout();
            }

            public void ApplyToChildren()
            {
                if (!ApplyToDescendants)
                    Modal.FindElement(By.CssSelector("ip-checkbox[data-label='.checkboxLabel'] label")).ClickWithTimeout();
            }
        }

    }

    class EntryInheritanceDeleteModal : ModalBase
    {
        const string Id = "inheritanceDeleteConfirmationModal";

        public EntryInheritanceDeleteModal(NgWebDriver driver) : base(driver, Id)
        {
        }

        public void Delete()
        {
            Modal.FindElement(By.CssSelector("button[translate='Delete']")).ClickWithTimeout();
        }

        public void WithoutApplyToChildren()
        {
            Modal.FindElement(By.CssSelector("ip-checkbox[data-label='workflows.entrycontrol.deleteConfirmation.checkboxLabel'] label")).ClickWithTimeout();
        }
    }

    internal static class KendoExt
    {
        public static bool AnyInherited(this KendoGrid grid)
        {
            return grid.Rows.Any(t => t.FindElements(By.CssSelector(".cpa-icon-inheritance")).Count == 1);
        }
    }
}