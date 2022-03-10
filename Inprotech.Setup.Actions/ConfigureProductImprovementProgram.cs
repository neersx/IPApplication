using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Newtonsoft.Json;

namespace Inprotech.Setup.Actions
{
    public class ConfigureProductImprovementProgram : ISetupAction
    {
        readonly IInprotechServerPersistingConfigManager _inprotechServerPersistingConfigManager;

        public ConfigureProductImprovementProgram(IInprotechServerPersistingConfigManager inprotechServerPersistingConfigManager)
        {
            _inprotechServerPersistingConfigManager = inprotechServerPersistingConfigManager;
        }

        public ConfigureProductImprovementProgram() : this(new InprotechServerPersistingConfigManager())
        {
        }

        public bool ContinueOnException => false;

        public string Description => "Configure Product Improvement Program";

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            var ctx = (SetupContext)context;
            var connectionString = (string)context["InprotechConnectionString"];

            if (!ctx.ContainsKey("UsageStatisticsSettings") || ctx.UsageStatisticsSettings == null)
            {
                return;
            }

            _inprotechServerPersistingConfigManager.SaveProductImprovement(connectionString, JsonConvert.SerializeObject(ctx.UsageStatisticsSettings));

            var integrationConnectionString = (string)context["IntegrationConnectionString"];
            using (var connection = new SqlConnection(integrationConnectionString))
            {
                connection.Open();
                var command = connection.CreateCommand();
                command.CommandText = @"IF EXISTS( SELECT * FROM JOBS WHERE [TYPE]= 'ServerAnalyticsJob')
                                            UPDATE JOBS SET ISACTIVE = @active WHERE [TYPE]= 'ServerAnalyticsJob';";

                var paramActive = command.Parameters.Add("@active", SqlDbType.Bit);
                paramActive.Value = ctx.UsageStatisticsSettings.FirmUsageStatisticsConsented ?? false;
                command.ExecuteNonQuery();
            }

            eventStream.PublishInformation("Persisting Product Improvement Program Settings");
        }
    }
}