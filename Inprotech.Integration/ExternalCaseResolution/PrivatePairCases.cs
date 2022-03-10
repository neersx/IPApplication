using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.ExternalCaseResolution
{
    public interface IPrivatePairCases
    {
        Dictionary<int, int> Resolve(IEnumerable<int> integrationCaseIds, bool exactMatch);
    }

    public class PrivatePairCases : IPrivatePairCases
    {
        readonly IDbContext _dbContext;
        readonly IRepository _repository;

        public PrivatePairCases(IDbContext dbContext, IRepository repository)
        {
            _dbContext = dbContext;
            _repository = repository;
        }

        public Dictionary<int, int> Resolve(IEnumerable<int> integrationCaseIds, bool exactMatch)
        {
            var cases = _repository.Set<Case>()
                                   .Where(_ =>
                                              integrationCaseIds.Contains(_.Id) && !_.CorrelationId.HasValue)
                                   .ToArray();

            var result = new Dictionary<int, int>();

            using (var command = _dbContext.CreateStoredProcedureCommand("apps_FindPrivatePairCaseMatches"))
            {
                command.CommandTimeout = 0;
                command.Parameters.AddRange(
                                            new[]
                                            {
                                                new SqlParameter("@psSystemCode", ExternalSystems.SystemCode(DataSourceType.UsptoPrivatePair)),
                                                new SqlParameter("@pbExactMatch", exactMatch),
                                                new SqlParameter("@pxPrivatePairCases", Build(cases).ToString())
                                            });

                using (var reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        var integrationCaseId = (int) reader["PrivatePairCaseKey"];
                        var inprotechCaseId = (int) reader["CaseKey"];

                        result.Add(integrationCaseId, inprotechCaseId);
                    }

                    return result;
                }
            }
        }

        static XElement Build(Case[] cases)
        {
            return
                new XElement("PrivatePair",
                             cases.Select(
                                          _ => new XElement("Case",
                                                            new XElement("PrivatePairCaseId", _.Id),
                                                            new XElement("ApplicationNumber", _.ApplicationNumber)
                                                           )));
        }
    }
}