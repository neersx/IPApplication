using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Processor.RunMappers
{
    public class RunStoredProcedureMapper : RunMapper
    {
        public RunStoredProcedureMapper(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver)
            : base(dbContext, securityContext, preferredCultureResolver)
        {
        }

        public override DataSet Execute(string storedProcedure, string parameters, string entryPointValue, RunDocItemParams runDocItemParams)
        {
            using (var dbCommand = _dbContext.CreateStoredProcedureCommand(storedProcedure))
            {
                dbCommand.CommandTimeout = runDocItemParams.CommandTimeout;
                SqlCommandBuilder.DeriveParameters(dbCommand);

                var entryPointParameterFound = false;
                string[] valueParameters = null;
                var iValueParameter = 0;

                if (!string.IsNullOrEmpty(parameters))
                {
                    valueParameters = parameters.Split(PARAMETER_SEPARATOR);
                }

                foreach (DbParameter dbParameter in dbCommand.Parameters)
                {
                    if (dbParameter.ParameterName == "@RETURN_VALUE")
                    {
                        continue;
                    }

                    switch (dbParameter.ParameterName)
                    {
                        case "@pnRowCount":
                            dbParameter.Value = 0;
                            break;
                        case "@pnUserIdentityId":
                        case "@gstrUserId":
                            dbParameter.Value = _securityContext.User.Id;
                            break;
                        case "@psCulture":
                        case "@gstrCulture":
                            dbParameter.Value = _preferredCultureResolver.Resolve();
                            break;
                        case "@pbCalledFromCentura":
                            dbParameter.Value = 0;
                            break;
                        case "@psEntryPoint":
                            dbParameter.Value = entryPointValue;
                            entryPointParameterFound = true;
                            break;
                        default:
                            if (entryPointParameterFound)
                            {
                                if (valueParameters != null && iValueParameter < valueParameters.Length)
                                {
                                    if (dbParameter.DbType == DbType.Boolean)
                                    {
                                        switch (valueParameters[iValueParameter])
                                        {
                                            case "0":
                                                dbParameter.Value = false;
                                                break;
                                            case "1":
                                                dbParameter.Value = true;
                                                break;
                                            default:
                                                dbParameter.Value = valueParameters[iValueParameter];
                                                break;
                                        }
                                    }
                                    else
                                    {
                                        dbParameter.Value = valueParameters[iValueParameter];
                                    }

                                    iValueParameter++;
                                }
                                else
                                {
                                    if (dbParameter.DbType == DbType.String)
                                    {
                                        dbParameter.Value = runDocItemParams.EmptyParamsAsNulls ? null : string.Empty;
                                    }
                                    else
                                    {
                                        dbParameter.Value = null;
                                    }
                                }
                            }
                            else
                            {
                                dbParameter.Value = entryPointValue;
                                entryPointParameterFound = true;
                            }

                            break;
                    }
                }

                var dataSet = new DataSet();
                new SqlDataAdapter(dbCommand).Fill(dataSet);
                return dataSet;
            }
        }
    }
}