using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Policing;

namespace Inprotech.Tests.Model.Components.Policing
{
    public class PolicingErrorBuilder : IBuilder<PolicingError>
    {
        static short _next = 1;

        readonly InMemoryDbContext _db;

        public PolicingErrorBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public int? CaseId { get; set; }

        public DateTime? StartTime { get; set; }

        public DateTime? LastModified { get; set; }

        public short? ErrorSeqNo { get; set; }

        public string ErrorMessage { get; set; }

        public PolicingError Build()
        {
            var @case = CaseId.HasValue
                ? _db.Set<Case>().SingleOrDefault(_ => _.Id == CaseId)
                : null;

            return new PolicingError(StartTime ?? Fixture.Today(), ErrorSeqNo ?? _next++)
            {
                CaseId = CaseId,
                Case = @case,
                LastModified = LastModified ?? Fixture.Today(),
                Message = ErrorMessage ?? Fixture.String()
            }.In(_db);
        }
    }

    public static class PolicingErrorBuilderExtension
    {
        public static PolicingErrorBuilder For(this PolicingErrorBuilder builder, Case @case)
        {
            builder.CaseId = @case.Id;
            return builder;
        }
    }
}