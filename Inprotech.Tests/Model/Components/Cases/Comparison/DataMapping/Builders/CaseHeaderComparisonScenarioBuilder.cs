using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class CaseHeaderComparisonScenarioBuilder : IBuilder<ComparisonScenario<CaseHeader>>
    {
        public CaseHeader CaseHeader { get; set; }

        public ComparisonScenario<CaseHeader> Build()
        {
            return new ComparisonScenario<CaseHeader>(CaseHeader ?? new CaseHeader(), ComparisonType.CaseHeader);
        }
    }
}