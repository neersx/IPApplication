using System.Collections.Generic;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    public static class TimeGridHelper
    {
        public static void TestColumnSelection(AngularKendoGrid entries, AngularColumnSelection columnSelector, NgWebDriver driver, Dictionary<string, string> hiddenColumns)
        {
            var columns = entries.HeaderColumnsFields;
            foreach (var hiddenColumn in hiddenColumns)
            {
                Assert.False(columns.Contains(hiddenColumn.Key), $"{hiddenColumn.Value} column is hidden by default");    
            }

            columnSelector.ColumnMenuButtonClick();
            Assert.IsTrue(columnSelector.IsColumnChecked("name"), "The Name column appears checked in the menu");
            columnSelector.ToggleGridColumn("name");
            columnSelector.ColumnMenuButtonClick();
            Assert.False(entries.HeaderColumnsFields.Contains("name"), "Name column is hidden in the grid");
            columnSelector.ColumnMenuButtonClick();
            Assert.IsFalse(columnSelector.IsColumnChecked("name"), "Name column is unchecked in the menu");

            columnSelector.ToggleGridColumn("totalUnits");
            columnSelector.ColumnMenuButtonClick();
            Assert.True(entries.HeaderColumnsFields.Contains("totalUnits"), "Units Column is displayed");
            
            driver.Navigate().Refresh();
            driver.WaitForAngularWithTimeout();

            Assert.False(entries.HeaderColumnsFields.Contains("name"), "Name Column is not displayed as per local saved setting");
            Assert.Contains("totalUnits", entries.HeaderColumnsFields, "Units Column is displayed as per local saved setting");

            columnSelector.ColumnMenuButtonClick();
            columnSelector.ResetButton.WithJs().Click();
            Assert.Contains("name", entries.HeaderColumnsFields, "Name Column is not displayed as per local saved setting");
            Assert.False(entries.HeaderColumnsFields.Contains("totalUnits"), "Units Column is displayed as per local saved setting");
        }
    }
}
