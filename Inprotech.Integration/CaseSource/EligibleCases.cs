using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Notifications;
using InprotechKaizen.Model.Components.Integration.PtoAccess;

namespace Inprotech.Integration.CaseSource
{
    public interface IEligibleCases
    {
        IEnumerable<EligibleCase> Resolve(DataDownload session, int savedQueryId, int executeAs);
    }

    public class EligibleCases : IEligibleCases
    {
        readonly IProvideCaseResolvers _caseResolverProvider;
        readonly IFilterDataExtractCases _dataExtractCases;
        readonly IBackgroundProcessLogger<EligibleCases> _logger;
        readonly IIndex<DataSourceType, ISourceRestrictor> _restrictors;

        public EligibleCases(IProvideCaseResolvers caseResolverProvider, IFilterDataExtractCases dataExtractCases, IIndex<DataSourceType, ISourceRestrictor> restrictors, IBackgroundProcessLogger<EligibleCases> logger)
        {
            _caseResolverProvider = caseResolverProvider;
            _dataExtractCases = dataExtractCases;
            _restrictors = restrictors;
            _logger = logger;
        }

        public IEnumerable<EligibleCase> Resolve(DataDownload session, int savedQueryId, int executeAs)
        {
            const int chunkSize = 10000;

            var systemCode = ExternalSystems.SystemCode(session.DataSourceType);

            var hasRestrictor = _restrictors.TryGetValue(session.DataSourceType, out var sourceRestrictor);

            var queryCaseIds = GetQueryCaseIds(session, savedQueryId, executeAs);

            var eligibleCasesInQuery = new List<EligibleCase>();

            var message = new StringBuilder();

            message.AppendLine($"Saved query {savedQueryId} yielded {queryCaseIds.Length} cases.");

            var all = new Stopwatch();

            all.Start();

            do
            {
                var chunk = new Stopwatch();
                chunk.Start();

                var currentChunk = queryCaseIds.Take(chunkSize).ToArray();
                queryCaseIds = queryCaseIds.Except(currentChunk).ToArray();

                var eligibleCaseItems = _dataExtractCases.For(systemCode, currentChunk);

                if (hasRestrictor)
                {
                    eligibleCaseItems = sourceRestrictor.Restrict(eligibleCaseItems, session.DownloadType);
                }

                var eligibleCases = eligibleCaseItems.Select(_ => new EligibleCase
                {
                    CaseKey = _.CaseKey,
                    ApplicationNumber = _.ApplicationNumber,
                    PublicationNumber = _.PublicationNumber,
                    RegistrationNumber = _.RegistrationNumber,
                    CountryCode = _.CountryCode,
                    SystemCode = _.SystemCode,
                    PropertyType = _.PropertyType
                });

                eligibleCasesInQuery.AddRange(eligibleCases.ToArray());

                chunk.Stop();

                message.AppendLine(chunk.Elapsed.ToString());
            }
            while (queryCaseIds.Any());

            all.Stop();

            message.AppendLine(all.Elapsed.ToString());

            if (all.Elapsed.TotalMinutes > 1)
            {
                _logger.Warning($"This {systemCode} schedule ({session.Id}) took {all.Elapsed}", message.ToString());
            }

            return eligibleCasesInQuery;
        }

        int[] GetQueryCaseIds(DataDownload session, int savedQueryId, int executeAs)
        {
            return _caseResolverProvider.Get(session)
                                        .GetCaseIds(session, savedQueryId, executeAs)
                                        .Distinct()
                                        .ToArray();
        }
    }
}