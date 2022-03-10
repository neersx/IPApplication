using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Cases.Comparison.Comparers;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using Case = InprotechKaizen.Model.Cases.Case;

namespace InprotechKaizen.Model.Components.Cases.Comparison
{
    public interface ICaseComparer
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        Task<ComparisonResult> Compare(Case @case, string cpaxml, string systemCode);
    }

    public class CaseComparer : ICaseComparer
    {
        readonly ICaseSecurity _caseSecurity;
        readonly IEnumerable<ISpecificComparer> _comparers;
        readonly ICpaXmlComparison _cpaXmlComparison;

        public CaseComparer(
            ICpaXmlComparison cpaXmlComparison,
            ICaseSecurity caseSecurity,
            IEnumerable<ISpecificComparer> comparers)
        {
            _cpaXmlComparison = cpaXmlComparison;
            _caseSecurity = caseSecurity;
            _comparers = comparers;
        }

        public async Task<ComparisonResult> Compare(Case @case, string cpaxml, string systemCode)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (string.IsNullOrWhiteSpace(systemCode)) throw new ArgumentNullException(nameof(systemCode));
            try
            {
                var comparisonScenarios = _cpaXmlComparison.FindComparisonScenarios(cpaxml, systemCode).ToArray();

                var cr = new ComparisonResult(systemCode);

                foreach (var comparer in _comparers)
                    comparer.Compare(@case, comparisonScenarios, cr);

                cr.Updateable = await _caseSecurity.CanAcceptChanges(@case);

                return cr;
            }
            catch (FailedMappingException ex)
            {
                var itemsByType = ex.DataSource.GroupBy(ds => ds.TypeId);

                return new ComparisonResult(systemCode)
                {
                    Errors =
                        itemsByType.Select(
                                           t => new ComparisonError
                                           {
                                               Type = ComparisonErrorTypes.MappingError,
                                               Key = ex.DataSource.First(_ => _.TypeId == t.Key).StructureName,
                                               Message = t.Select(c => c.Code ?? c.Description)
                                           })
                };
            }
        }
    }
}