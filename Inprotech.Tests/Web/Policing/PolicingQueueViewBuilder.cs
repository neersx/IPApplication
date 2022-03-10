using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Policing.Monitoring;
using InprotechKaizen.Model.Policing;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingQueueViewBuilder : IBuilder<PolicingQueueView>
    {
        readonly InMemoryDbContext _db;

        public PolicingQueueViewBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public string Status { get; set; }

        public string User { get; set; }

        public string UserKey { get; set; }

        public string CaseRef { get; set; }

        public PolicingQueueView Build()
        {
#pragma warning disable 618
            return new PolicingQueueView
#pragma warning restore 618
            {
                Status = Status ?? this.RandomStatus(),
                UserKey = UserKey ?? Fixture.String(),
                User = User ?? Fixture.String(),
                CaseReference = CaseRef ?? Fixture.String()
            }.In(_db);
        }
    }

    public static class PolicingQueueViewBuilderExt
    {
        static readonly string[] KnownStatuses = {"waiting-to-start", "in-progress", "failed", "in-error", "on-hold", "blocked"};

        public static string RandomStatus(this PolicingQueueViewBuilder builder)
        {
            return KnownStatuses.ElementAt(new Random().Next(0, 5));
        }

        public static PolicingQueueViewBuilder PickAnotherStatusButNot(this PolicingQueueViewBuilder builder, string status)
        {
            builder.Status = KnownStatuses.Except(new[] {status}).First();
            return builder;
        }

        public static PolicingQueueViewBuilder PickAnotherMappedStatusNotIn(this PolicingQueueViewBuilder builder, string knownStatus)
        {
            builder.Status = KnownStatuses.Except(PolicingQueueKnownStatus.MappedStatus(knownStatus)).First();
            return builder;
        }

        public static PolicingQueueViewBuilder SetRandomMappedStatus(this PolicingQueueViewBuilder builder, string knownStatus)
        {
            var mappedStatuses = PolicingQueueKnownStatus.MappedStatus(knownStatus);
            builder.Status = mappedStatuses.ElementAt(new Random().Next(0, mappedStatuses.Length - 1));
            return builder;
        }
    }
}