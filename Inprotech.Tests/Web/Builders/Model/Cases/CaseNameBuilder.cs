using System;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CaseNameBuilder : IBuilder<CaseName>
    {
        readonly InMemoryDbContext _db;

        public CaseNameBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public Case Case { get; set; }
        public NameType NameType { get; set; }
        public Name Name { get; set; }
        public short? Sequence { get; set; }
        public Name AttentionName { get; set; }
        public NameVariant NameVariant { get; set; }
        public Address Address { get; internal set; }
        public virtual TableCode CorrespondenceReceived { get; set; }
        public DateTime? ExpiryDate { get; set; }

        public string Reference { get; set; }
        public decimal? BillPercentage { get; set; }

        public CaseName Build()
        {
            var name = Name ?? new NameBuilder(_db).Build();

            return new CaseName(
                                Case ?? new CaseBuilder().Build(),
                                NameType ?? new NameTypeBuilder().Build(),
                                name,
                                Sequence ?? Fixture.Short(),
                                AttentionName,
                                NameVariant ?? new NameVariantBuilder(_db)
                                               {
                                                   Name = name
                                               }.Build(),
                                Address,
                                CorrespondenceReceived ?? new TableCodeBuilder().Build())
                   {
                       ExpiryDate = ExpiryDate,
                       Reference = Reference,
                       BillingPercentage = BillPercentage
                   };
        }

        public CaseName BuildWithCase(Case @case, decimal isInherited = 0)
        {
            var name = Name ?? new NameBuilder(_db).Build();

            var caseName = new CaseName(
                                        @case,
                                        NameType ?? new NameTypeBuilder().Build(),
                                        name,
                                        Sequence ?? Fixture.Short(),
                                        isInherited,
                                        AttentionName,
                                        NameVariant ?? new NameVariantBuilder(_db)
                                                       {
                                                           Name = name
                                                       }.Build(),
                                        Address,
                                        CorrespondenceReceived ?? new TableCodeBuilder().Build())
                           {
                               ExpiryDate = ExpiryDate, 
                               Reference = Reference,
                               BillingPercentage = BillPercentage
                           };

            @case.CaseNames.Add(caseName);
            return caseName;
        }
    }

    public static class CaseNameBuilderExt
    {
        public static CaseNameBuilder WithAddress(this CaseNameBuilder builder, Address address)
        {
            builder.Address = address;
            return builder;
        }
    }
}