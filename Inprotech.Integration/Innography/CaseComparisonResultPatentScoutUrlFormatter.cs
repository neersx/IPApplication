using System;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;

namespace Inprotech.Integration.Innography
{
    public class CaseComparisonResultPatentScoutUrlFormatter : ISourceCaseUrlFormatter
    {
        readonly IPatentScoutUrlFormatter _patentScoutUrlFormatter;

        public CaseComparisonResultPatentScoutUrlFormatter(
            IPatentScoutUrlFormatter patentScoutUrlFormatter)
        {
            _patentScoutUrlFormatter = patentScoutUrlFormatter;
        }

        public Uri Format(ComparisonResult comparisonResult, bool isCpaSso)
        {
            if (comparisonResult == null) throw new ArgumentNullException(nameof(comparisonResult));
            if (comparisonResult.Case == null) throw new ArgumentNullException(nameof(comparisonResult.Case));

            if (string.IsNullOrWhiteSpace(comparisonResult.Case.SourceId))
            {
                return null;
            }

            return _patentScoutUrlFormatter.CreatePatentScoutReferenceLink(comparisonResult.Case.SourceId, isCpaSso);
        }
    }
}