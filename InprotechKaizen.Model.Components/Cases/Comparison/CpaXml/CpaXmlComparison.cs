using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;

namespace InprotechKaizen.Model.Components.Cases.Comparison.CpaXml
{
    public interface ICpaXmlComparison
    {
        IEnumerable<ComparisonScenario> FindComparisonScenarios(string source, string sourceSystem);
    }

    public class CpaXmlComparison : ICpaXmlComparison
    {
        readonly IComparisonPreprocessor _comparisonPreprocessor;
        readonly IEnumerable<IComparisonScenarioResolver> _comparisonScenarioResolvers;
        readonly ICpaXmlCaseDetailsLoader _cpaXmlCaseDetailsLoader;

        public CpaXmlComparison(
            IComparisonPreprocessor comparisonPreprocessor,
            ICpaXmlCaseDetailsLoader cpaXmlCaseDetailsLoader,
            IEnumerable<IComparisonScenarioResolver> comparisonScenarioResolvers)
        {
            _comparisonPreprocessor = comparisonPreprocessor;
            _cpaXmlCaseDetailsLoader = cpaXmlCaseDetailsLoader;
            _comparisonScenarioResolvers = comparisonScenarioResolvers;
        }

        public IEnumerable<ComparisonScenario> FindComparisonScenarios(string source, string sourceSystem)
        {
            if (string.IsNullOrWhiteSpace(source)) throw new ArgumentNullException(nameof(source));
            if (string.IsNullOrWhiteSpace(sourceSystem)) throw new ArgumentNullException(nameof(sourceSystem));

            var comparisonScenarios = ComparisonScenariosFrom(source, sourceSystem);

            return _comparisonPreprocessor.MapCodes(comparisonScenarios, sourceSystem);
        }

        IEnumerable<ComparisonScenario> ComparisonScenariosFrom(string cpaXml, string sourceSystem)
        {
            var data = _cpaXmlCaseDetailsLoader.Load(cpaXml);

            if (data.caseDetails == null)
            {
                yield break;
            }

            foreach (var comparisonScenarios in _comparisonScenarioResolvers
                                                .Where(_ => _.IsAllowed(sourceSystem))
                                                .Select(_ => _.Resolve(data.caseDetails, data.messages)))
            {
                foreach (var comparisonScenario in comparisonScenarios)
                    yield return comparisonScenario;
            }
        }
    }
}