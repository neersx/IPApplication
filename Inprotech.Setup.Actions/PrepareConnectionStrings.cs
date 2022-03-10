using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class PrepareConnectionStrings : ISetupAction
    {
        public string Description => "Prepare connection strings";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var inprotechConnectionString = (string) context["InprotechConnectionString"];

            context["IntegrationConnectionString"] = context.ContainsKey("IntegrationConnectionString")
                ? context["IntegrationConnectionString"]
                : IntegrationConnectionString(inprotechConnectionString);

            context["IntegrationAdministrationConnectionString"] = context.ContainsKey("IntegrationAdministrationConnectionString")
                ? context["IntegrationAdministrationConnectionString"]
                : IntegrationAdministrationConnectionString(inprotechConnectionString);

            context["InprotechAdministrationConnectionString"] = context.ContainsKey("InprotechAdministrationConnectionString")
                ? context["InprotechAdministrationConnectionString"]
                : InprotechAdministrationConnectionString(inprotechConnectionString);
        }

        static string InprotechAdministrationConnectionString(string connectionString)
        {
            var builder = new SqlConnectionStringBuilder(connectionString);

            if (builder.IntegratedSecurity)
                return builder.ConnectionString;

            builder.IntegratedSecurity = true;

            return builder.ConnectionString;
        }

        static string IntegrationConnectionString(string connectionString)
        {
            var builder = new SqlConnectionStringBuilder(connectionString);

            builder.InitialCatalog = builder.InitialCatalog + "Integration";

            return builder.ConnectionString;
        }

        static string IntegrationAdministrationConnectionString(string connectionString)
        {
            var builder = new SqlConnectionStringBuilder(connectionString);

            builder.InitialCatalog = builder.InitialCatalog + "Integration";

            if (builder.IntegratedSecurity)
                return builder.ConnectionString;

            builder.IntegratedSecurity = true;

            return builder.ConnectionString;
        }
    }
}