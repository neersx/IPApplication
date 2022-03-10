using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Components.Integration.PtoAccess;

namespace Inprotech.Integration.Notifications
{
    public interface IMatchingCases
    {
        Dictionary<int, int> Resolve(string sources, params int[] cases);
    }

    public class MatchingCases : IMatchingCases
    {
        readonly IFilterDataExtractCases _dataExtractCases;
        readonly IRepository _repository;

        public MatchingCases(IRepository repository, IFilterDataExtractCases dataExtractCases)
        {
            _repository = repository;
            _dataExtractCases = dataExtractCases;
        }

        public Dictionary<int, int> Resolve(string sources, params int[] cases)
        {
            var eligibleCases = _dataExtractCases.For(sources, cases)
                                                 .ToArray()
                                                 .Where(_ => ExternalSystems.DataSourceOrNull(_.SystemCode).HasValue)
                                                 .ToArray();

            var correlationIds = eligibleCases.Select(c => c.CaseKey);
            var result = new Dictionary<int, int>();
            foreach (var integrationCase in _repository
                .Set<Case>()
                .Where(_ => _.CorrelationId.HasValue && correlationIds.Contains(_.CorrelationId.Value))
                .ToArray())
            {
                var intCaseId = integrationCase.CorrelationId.GetValueOrDefault();

                var eligibleCase = eligibleCases
                    .SingleOrDefault(_ =>
                                         _.CaseKey == intCaseId &&
                                         ExternalSystems.DataSource(_.SystemCode) == integrationCase.Source);

                if (eligibleCase == null)
                {
                    continue;
                }

                result.Add(integrationCase.Id, eligibleCase.CaseKey);
            }
            return result;
        }
    }
}