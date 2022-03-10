using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text.RegularExpressions;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Processor.RunMappers
{
    public class RunQueryMapper : RunMapper
    {
        public RunQueryMapper(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver)
            : base(dbContext, securityContext, preferredCultureResolver)
        {
        }

        public override DataSet Execute(string sqlQuery, string parameters, string entryPointValue, RunDocItemParams runDocItemParams)
        {
            if (runDocItemParams == null) throw new ArgumentNullException(nameof(runDocItemParams));
            if (string.IsNullOrWhiteSpace(entryPointValue)) throw new ArgumentNullException(nameof(entryPointValue));
            if (string.IsNullOrWhiteSpace(sqlQuery)) throw new ArgumentNullException(nameof(sqlQuery));

            using (var dbCommand = _dbContext.CreateSqlCommand(sqlQuery))
            {
                var parametersFromQuery = GetParametersFromQuery(sqlQuery);
                if (parametersFromQuery.Count > 0)
                {
                    var valueParameters = string.IsNullOrEmpty(parameters)
                                              ? new List<string>()
                                              : parameters.Split(PARAMETER_SEPARATOR).ToList();

                    foreach (var paramName in parametersFromQuery)
                    {
                        var parameterIndex = int.Parse(paramName.Remove(0, 2));
                        var parameterValue = valueParameters.ElementAtOrDefault(parameterIndex-1);
                        if (string.IsNullOrEmpty(parameterValue))
                            parameterValue = runDocItemParams.EmptyParamsAsNulls ? null : string.Empty;

                        sqlQuery = sqlQuery.Replace(paramName, paramName.Replace(":", "@"));
                        dbCommand.Parameters.AddWithValue(paramName.Substring(1), parameterValue);
                    }
                }
                if (sqlQuery.IndexOf(":gstrEntryPoint", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    sqlQuery = Regex.Replace(sqlQuery,":gstrEntryPoint", "@gstrEntryPoint", RegexOptions.IgnoreCase);
                    dbCommand.Parameters.AddWithValue("gstrEntryPoint", entryPointValue);
                }
                if (sqlQuery.IndexOf(":gstrUserId", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    sqlQuery = Regex.Replace(sqlQuery,":gstrUserId", "@gstrUserId", RegexOptions.IgnoreCase);
                    dbCommand.Parameters.AddWithValue("gstrUserId", _securityContext.User.Name.Id);
                }
                if (sqlQuery.IndexOf(":gstrCulture", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    sqlQuery = Regex.Replace(sqlQuery,":gstrCulture", "@gstrCulture", RegexOptions.IgnoreCase);
                    dbCommand.Parameters.AddWithValue("gstrCulture", _preferredCultureResolver.Resolve());
                }
                if (!runDocItemParams.ConcatNullYieldsNull)
                {
                    dbCommand.CommandText = $"SET CONCAT_NULL_YIELDS_NULL OFF{Environment.NewLine}{sqlQuery}";
                }
                else
                {
                    dbCommand.CommandText = sqlQuery;
                }

                dbCommand.CommandTimeout = runDocItemParams.CommandTimeout;

                var dataSet = new DataSet();
                new SqlDataAdapter(dbCommand).Fill(dataSet);
                return dataSet;
            }
        }

        static List<string> GetParametersFromQuery(string sqlQuery)
        {
            var listParams = new List<string>();
            var matches = Regex.Matches(sqlQuery, @"(:p([\d])+)");
            for (var i = 0; i < matches.Count; i++)
                listParams.Add(matches[i].Value);

            return listParams.Distinct().ToList();
        }
    }
}
