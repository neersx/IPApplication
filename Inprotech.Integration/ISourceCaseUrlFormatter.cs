using System;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;

namespace Inprotech.Integration
{
    public interface ISourceCaseUrlFormatter
    {
        Uri Format(ComparisonResult comparisonResult, bool isCpaSso);
    }
}