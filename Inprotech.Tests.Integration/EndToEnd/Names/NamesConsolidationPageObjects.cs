using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Names
{
    public class NamesConsolidationPageObjects : PageObject
    {
        public NamesConsolidationPageObjects(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public ButtonInput Add => new ButtonInput(Driver).ById("names-add-btn");

        public ButtonInput BtnNamesConsolidation => new ButtonInput(Driver).ById("execute-names-consolidation");

        ButtonInput ClearButton => new ButtonInput(Driver).ByClassName("btn-clear");

        public PickList NamesPicklist => new PickList(Driver).ById("names-picklist");

        public KendoGrid NamesToConsolidateGrid => new KendoGrid(Driver, "names-consolidation-grid");

        public NamesConfirmationModal ConfirmModal => new NamesConfirmationModal(Driver);

        public enum NamesToConsolidateGridIndexes
        {
            ErrorInfo = 1,
            Name = 2,
            NameCode = 3,
            Remarks = 4,
            NameNo = 5,
            DateCeased = 6,
            MergeIcon = 7
        }

        public void OpenNamePicklistViaAddButton()
        {
            Add.Click();
        }

        public IEnumerable<int> RowsWithMergeIconShown()
        {
            List<int> rowIndex = new List<int>();
            var rows = NamesToConsolidateGrid.Rows;
            for (var i = 0; i < rows.Count; i++)
            {
                if (rows[i].FindElements(By.ClassName("cpa-icon-merge")).Count > 0)
                    rowIndex.Add(i);
            }

            return rowIndex;
        }

        public void ClickMergeIcon(int rowIndex)
        {
            NamesToConsolidateGrid.Cell(rowIndex, (int)NamesToConsolidateGridIndexes.MergeIcon).FindElement(By.ClassName("cpa-icon-merge")).ClickWithTimeout();
        }

        public string NamesToConsolidateGridText(int rowIndex, NamesToConsolidateGridIndexes index)
        {
            return NamesToConsolidateGrid.CellText(rowIndex, (int)index);
        }

        public IEnumerable<string> NamesDetailsShown()
        {
            return Driver.FindElements(By.CssSelector(".readonly-label-group a")).Select(_ => _.Text).Concat(Driver.FindElements(By.CssSelector(".readonly-label-group span")).Select(_ => _.Text));
        }

        public void Clear(bool hasChanges)
        {
            ClearButton.Click();
            if (hasChanges)
                new CommonPopups(Driver).DiscardChangesModal.Discard();
        }

        public class NamesConfirmationModal : ConfirmModal
        {
            const string Id = "namesConsolidationConfirmationController";

            public NamesConfirmationModal(NgWebDriver driver) : base(driver, Id)
            {
            }
        }
    }
}