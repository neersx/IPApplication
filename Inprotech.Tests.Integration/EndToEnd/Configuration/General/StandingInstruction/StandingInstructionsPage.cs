using System.Collections.ObjectModel;
using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.StandingInstruction
{
    public class StandingInstructionsPage : PageObject
    {
        public StandingInstructionsPage(NgWebDriver driver) : base(driver)
        {
        }

        public PickList InstructionType => new PickList(Driver).ById("instructiontype-picklist");

        public InstructionsGrid Instructions => new InstructionsGrid(Driver);

        public CharacteristicsGrid Characteristics => new CharacteristicsGrid(Driver);

        public void Save()
        {
            Driver.FindElement(By.CssSelector(".page-title .btn-save")).WithJs().Click();
        }
        
        public class InstructionsGrid : PageObject
        {
            const string GridId = "instructions-grid";

            public InstructionsGrid(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
            {
            }

            public ReadOnlyCollection<NgWebElement> EditableRows => Driver.FindElements(By.CssSelector($"#{GridId} tbody tr input"));

            public ReadOnlyCollection<NgWebElement> SelectedRows => Driver.FindElements(By.CssSelector($"#{GridId} tbody tr.selected input"));

            public InlineAlert InformationText => new InlineAlert(Driver, Driver.FindElement(By.Id(GridId)));

            public ButtonInput AddButton => new ButtonInput(Driver).ByCssSelector($"#{GridId} .add-row");

            public void SelectInstruction(int index)
            {
                Driver.FindElements(NgBy.Model("instr.obj.description")).ElementAt(index).WithJs().Click();
            }

            public void EnterText(int index, string text)
            {
                SelectInstruction(index);

                EditableRows.ElementAt(index).Clear();

                EditableRows.ElementAt(index).SendKeys(text);

                EditableRows.ElementAt(index).SendKeys(Keys.Tab);
            }

            public void DeleteInstruction(int index)
            {
                Driver.FindElements(By.CssSelector($"#{GridId} .cpa-icon-trash-o")).ElementAt(index).Click();
            }

            public int NumberOfRowsInState(string state)
            {
                return Driver.FindElements(By.CssSelector($"#{GridId} .{state}")).Count;
            }
        }

        public class CharacteristicsGrid : PageObject
        {
            const string GridId = "characteristics-grid";

            public CharacteristicsGrid(NgWebDriver driver) : base(driver)
            {
            }

            public ReadOnlyCollection<NgWebElement> DisplayedRows => Driver.FindElements(NgBy.Model("characteristic.obj.description"));

            public ReadOnlyCollection<NgWebElement> Togglers => Driver.FindElements(By.CssSelector($"#{GridId} input[type=checkbox]"));

            public InlineAlert InformationText => new InlineAlert(Driver, Driver.FindElement(By.Id(GridId)));

            public ButtonInput AddButton => new ButtonInput(Driver).ByCssSelector($"#{GridId} .add-row");

            public void SelectCharateristic(int index)
            {
                DisplayedRows.ElementAt(index).WithJs().Click();
            }

            public void EnterText(int index, string text)
            {
                SelectCharateristic(index);

                DisplayedRows.ElementAt(index).Clear();

                DisplayedRows.ElementAt(index).SendKeys(text);

                DisplayedRows.ElementAt(index).SendKeys(Keys.Tab);
            }

            public void DeleteCharacteristic(int index)
            {
                Driver.FindElements(By.CssSelector($"#{GridId} .cpa-icon-trash-o")).ElementAt(index).Click();
            }

            public int NumberOfRowsInState(string state)
            {
                return Driver.FindElements(By.CssSelector($"#{GridId} .{state}")).Count;
            }
        }
    }
}