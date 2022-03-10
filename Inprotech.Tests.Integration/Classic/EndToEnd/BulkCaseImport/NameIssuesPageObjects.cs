using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Names;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport
{
    public class NameIssuesPageObjects : PageObject
    {
        public NameIssuesPageObjects(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement BatchIdentifier => Driver.FindElement(By.Id("batchIdentifier"));

        public ReadOnlyCollection<NgWebElement> MapCandidates => Driver.FindElements(NgBy.Repeater("m in selectedUnresolved.mapCandidates"));

        public ReadOnlyCollection<NgWebElement> NameIssues => Driver.FindElements(NgBy.Repeater("n in viewData.nameIssues"));

        public NgWebElement BatchSummaryLink => Driver.FindElement(By.Id("niTransactionLink"));

        public PickList CandidateInput => new PickList(Driver).ByName(string.Empty, "namePicklist"); 

        public string MapCandidateDetailsByBinding(int index, string binding)
        {
            return MapCandidates[index].FindElement(NgBy.Binding(binding)).Text;
        }

        public IEnumerable<ComparisonPanelRow> ComparisonPanel
        {
            get
            {
                return Driver.FindElements(By.CssSelector("table .nr-field-name"))
                             .Select(td => new ComparisonPanelRow(td)).ToList();
            }
        }

        public void SelectUnresolvedName(int index)
        {
            NameIssues[index].WithJs().Click();
        }
    }

    public class ComparisonPanelRow
    {
        public ComparisonPanelRow(NgWebElement element)
        {
            var tr = element.GetParent().FindElements(By.CssSelector("td"));

            Field = tr[0].Text;

            Imported = tr[1].Text;

            Selected = tr[2].Text;
        }

        public string Field { get; }

        public string Imported { get; }

        public string Selected { get; }
    }

    public static class ComparisonEnumerableExt
    {
        public static ComparisonPanelRow ByField(this IEnumerable<ComparisonPanelRow> rows, string fieldName)
        {
            return rows.Single(_ => _.Field == fieldName);
        }
    }

    public class Names
    {
        public Name Org1 { get; set; }

        public Name Org2 { get; set; }

        public Name Ind1 { get; set; }

        public Name Ind2 { get; set; }

        public Name Ind3 { get; set; }
    }
}