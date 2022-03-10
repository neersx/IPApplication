using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;

namespace Inprotech.Setup.Actions
{
    public class VerifyLoginInIntegrationDatabase : ISetupAction
    {
        public string Description => "Verify login in Integration database";

        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if(context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            var inprotechConnectionString = (string)context["InprotechConnectionString"];
            var integrationAdministrationConnectionString = (string)context["IntegrationAdministrationConnectionString"];            
            var serviceUser = (string)context["ServiceUser"];
            
            var builder = new SqlConnectionStringBuilder(inprotechConnectionString);

            eventStream.PublishInformation(integrationAdministrationConnectionString);
            if(builder.IntegratedSecurity)
            {
                eventStream.PublishInformation($"Integrated Security=true. user={serviceUser}");
                DatabaseUtility.EnsureWindowsUserLogin(integrationAdministrationConnectionString, serviceUser.ToCanonicalUserName());
            }
            else
            {
                eventStream.PublishInformation($"Integrated Security=false. user={builder.UserID}");
                DatabaseUtility.EnsureSqlUserLogin(integrationAdministrationConnectionString, builder.UserID);
            }
        }
    }
}