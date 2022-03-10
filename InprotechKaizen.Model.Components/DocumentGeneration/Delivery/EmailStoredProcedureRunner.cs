using System;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Exceptions;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Delivery
{
    public interface IEmailStoredProcedureRunner
    {
        Task<EmailRecipients> Run(int activityId, string externallyProvidedEmailRecipientResolver);
    }

    public class EmailStoredProcedureRunner : IEmailStoredProcedureRunner
    {
        readonly IDbContext _dbContext;
        readonly IBackgroundProcessLogger<EmailStoredProcedureRunner> _logger;

        public EmailStoredProcedureRunner(IDbContext dbContext, IBackgroundProcessLogger<EmailStoredProcedureRunner> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task<EmailRecipients> Run(int activityId, string externallyProvidedEmailRecipientResolver)
        {
            if (externallyProvidedEmailRecipientResolver == null) throw new ArgumentNullException(nameof(externallyProvidedEmailRecipientResolver));

            try
            {
                _logger.Debug($"Resolving Email Recipients using {externallyProvidedEmailRecipientResolver} with activityId: {activityId}");

                using (var command = _dbContext.CreateStoredProcedureCommand(externallyProvidedEmailRecipientResolver))
                {
                    command.Parameters.AddWithValue("@pnActivityId", activityId);

                    using (var xmlReader = await command.ExecuteXmlReaderAsync())
                    {
                        var doc = XDocument.Load(xmlReader);

                        var root = doc.Element("eMailAddresses");
                        if (root == null) throw new Exception($"Unexpected result returned by {externallyProvidedEmailRecipientResolver}");

                        return new EmailRecipients((string) root.Element("Main"),
                                                   (string) root.Element("CC"),
                                                   (string) root.Element("BCC"))
                        {
                            Subject = (string) root.Element("EMAILSUBJECT")
                        };
                    }
                }
            }
            catch (Exception e)
            {
                var message = $"Execution of {externallyProvidedEmailRecipientResolver} with activityId: {activityId} has failed.";

                throw new CustomStoredProcedureErrorException(externallyProvidedEmailRecipientResolver, message, e);
            }
        }
    }
}