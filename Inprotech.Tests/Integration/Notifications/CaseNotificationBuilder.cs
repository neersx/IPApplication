using System;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders;

namespace Inprotech.Tests.Integration.Notifications
{
    public class CaseNotificationBuilder : IBuilder<CaseNotification>
    {
        readonly InMemoryDbContext _db;

        public CaseNotificationBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public string Body { get; set; }

        public DateTime? UpdatedOn { get; set; }

        public string ApplicationNumber { get; set; }

        public string PublicationNumber { get; set; }

        public string RegistrationNumber { get; set; }

        public int? CaseId { get; set; }

        public CaseNotificateType? Type { get; set; }

        public DataSourceType? SourceType { get; set; }

        public CaseNotification Build()
        {
            var caseId = Fixture.Integer();
            return new CaseNotification
            {
                CaseId = caseId,
                UpdatedOn = UpdatedOn ?? Fixture.Today(),
                Type = Type ?? CaseNotificateType.CaseUpdated,
                Body = Body,
                Case = new Case
                {
                    Id = caseId,
                    Source = SourceType ?? DataSourceType.UsptoPrivatePair,
                    ApplicationNumber = ApplicationNumber,
                    PublicationNumber = PublicationNumber,
                    RegistrationNumber = RegistrationNumber,
                    CorrelationId = CaseId
                }.In(_db)
            }.In(_db);
        }
    }
}