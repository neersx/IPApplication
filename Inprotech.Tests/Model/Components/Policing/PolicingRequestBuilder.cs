using System;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Policing;

namespace Inprotech.Tests.Model.Components.Policing
{
    public class PolicingRequestBuilder : IBuilder<PolicingRequest>
    {
        readonly InMemoryDbContext _db;

        public PolicingRequestBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public int? CaseId { get; set; }

        public DateTime? DateEntered { get; set; }

        public DateTime? LastModified { get; set; }

        public decimal? OnHold { get; set; }

        public decimal? IsSystemGenerated { get; set; }

        public PolicingRequest Build()
        {
            return new PolicingRequest(CaseId)
            {
                DateEntered = DateEntered ?? Fixture.Today(),
                LastModified = LastModified ?? Fixture.Today(),
                OnHold = OnHold ?? 1,
                IsSystemGenerated = IsSystemGenerated ?? 1
            }.In(_db);
        }
    }
}